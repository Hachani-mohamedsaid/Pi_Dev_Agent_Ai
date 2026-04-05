import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/utils/guest_interview_link.dart';
import '../../injection_container.dart';
import '../models/evaluation.dart';

/// Demande au backend d’**envoyer l’e-mail** au candidat (Resend, SMTP, etc.).
/// Sans cet endpoint, seul `mailto:` ou la copie du lien est possible.
class InterviewInviteEmailApiService {
  InterviewInviteEmailApiService();

  Future<InviteEmailSendResult> sendGuestInterviewInvite(
    Evaluation evaluation,
  ) async {
    final to = (evaluation.candidateEmail ?? '').trim();
    if (to.isEmpty) {
      return InviteEmailSendResult(
        kind: InviteEmailSendKind.clientError,
        message: 'E-mail candidat manquant sur la fiche.',
      );
    }

    final token =
        await InjectionContainer.instance.authLocalDataSource.getAccessToken();
    if (token == null || token.isEmpty) {
      return InviteEmailSendResult(
        kind: InviteEmailSendKind.clientError,
        message: 'Session expirée — reconnectez-vous.',
      );
    }

    final uri = Uri.parse(
      '$interviewApiRootUrl$interviewsSendInviteEmailPath',
    );
    final link = guestInterviewLinkString(evaluation);
    final payload = <String, dynamic>{
      'to': to,
      'guestInterviewUrl': link,
      if ((evaluation.evaluationId ?? '').trim().isNotEmpty)
        'evaluationId': evaluation.evaluationId!.trim(),
      if ((evaluation.candidateName ?? '').trim().isNotEmpty)
        'candidateName': evaluation.candidateName!.trim(),
      if ((evaluation.jobTitle ?? '').trim().isNotEmpty)
        'jobTitle': evaluation.jobTitle!.trim(),
    };

    try {
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return const InviteEmailSendResult(kind: InviteEmailSendKind.success);
      }
      if (res.statusCode == 404 || res.statusCode == 501) {
        return InviteEmailSendResult(
          kind: InviteEmailSendKind.notImplemented,
          message: 'Le serveur ne propose pas encore l’envoi automatique d’e-mails.',
        );
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        return InviteEmailSendResult(
          kind: InviteEmailSendKind.clientError,
          message: 'Accès refusé — reconnectez-vous.',
        );
      }
      final hint = _messageFromBody(res.body);
      return InviteEmailSendResult(
        kind: InviteEmailSendKind.serverError,
        message: hint ?? 'Erreur serveur (${res.statusCode}).',
      );
    } catch (e) {
      return InviteEmailSendResult(
        kind: InviteEmailSendKind.networkError,
        message: 'Réseau indisponible ou délai dépassé.',
      );
    }
  }

  String? _messageFromBody(String raw) {
    try {
      final d = jsonDecode(raw);
      if (d is Map && d['message'] is String) return d['message'] as String;
    } catch (_) {}
    return null;
  }
}

enum InviteEmailSendKind {
  success,
  notImplemented,
  clientError,
  serverError,
  networkError,
}

class InviteEmailSendResult {
  const InviteEmailSendResult({required this.kind, this.message});

  final InviteEmailSendKind kind;
  final String? message;
}
