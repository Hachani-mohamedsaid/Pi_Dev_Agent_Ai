import 'package:flutter/foundation.dart';

import '../../data/models/evaluation.dart';

/// Construit l’URL **publique** d’entretien candidat (sans compte).
///
/// Sur le web, utilise l’origine actuelle (`Uri.base`). Pour les builds où `Uri.base`
/// n’est pas l’URL publique (ex. APK), définir `--dart-define=APP_PUBLIC_ORIGIN=https://ton-app.web.app`.
///
/// ⚠️ En production, un **jeton signé** côté backend doit remplacer les paramètres en clair.
///
/// Le backend peut ajouter `token=` (JWT invité) et `sid=` (session serveur) à l’URL pour
/// l’entretien réel + envoi des événements proctoring.
Uri guestInterviewUriFor(Evaluation evaluation) {
  const originDefine = String.fromEnvironment('APP_PUBLIC_ORIGIN', defaultValue: '');
  final trimmed = originDefine.trim().replaceAll(RegExp(r'/$'), '');

  Uri base;
  if (trimmed.isNotEmpty) {
    final o = Uri.parse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    base = o;
  } else {
    base = Uri.base;
  }

  final qp = <String, String>{
    if ((evaluation.evaluationId ?? '').trim().isNotEmpty)
      'eid': evaluation.evaluationId!.trim(),
    if ((evaluation.candidateName ?? '').trim().isNotEmpty)
      'name': evaluation.candidateName!.trim(),
    if ((evaluation.jobTitle ?? '').trim().isNotEmpty)
      'job': evaluation.jobTitle!.trim(),
    if ((evaluation.candidateEmail ?? '').trim().isNotEmpty)
      'email': evaluation.candidateEmail!.trim(),
  };

  return Uri(
    scheme: base.scheme.isNotEmpty ? base.scheme : 'https',
    host: base.host.isNotEmpty ? base.host : 'localhost',
    port: base.hasPort ? base.port : null,
    path: '/guest-interview',
    queryParameters: qp.isEmpty ? null : qp,
  );
}

/// Lien prêt à coller dans un e-mail ou message.
String guestInterviewLinkString(Evaluation evaluation) =>
    guestInterviewUriFor(evaluation).toString();

/// Client mail avec destinataire, sujet et corps (lien d’entretien).
/// Retourne `null` si l’e-mail candidat est absent — utiliser [guestInterviewLinkString] à la place.
Uri? guestInterviewMailtoUri(Evaluation evaluation) {
  final to = (evaluation.candidateEmail ?? '').trim();
  if (to.isEmpty) return null;

  final link = guestInterviewLinkString(evaluation);
  final greetingName = (evaluation.candidateName ?? '').trim();
  final salutation =
      greetingName.isNotEmpty ? 'Bonjour $greetingName,' : 'Bonjour,';
  final job = (evaluation.jobTitle ?? 'le poste proposé').trim();

  final subject = 'Lien pour votre entretien assisté — $job';
  final body = StringBuffer()
    ..writeln(salutation)
    ..writeln()
    ..writeln(
      'Vous êtes invité(e) à passer un entretien assisté en ligne pour : $job.',
    )
    ..writeln()
    ..writeln('Ouvrez ce lien dans votre navigateur (aucun compte requis) :')
    ..writeln(link)
    ..writeln()
    ..writeln('Cordialement,');

  // `Uri.queryParameters` produit des `+` pour les espaces ; Apple Mail les affiche tels quels.
  // `encodeComponent` → `%20`, rendu correct dans le client mail.
  final q =
      'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body.toString())}';
  return Uri.parse('mailto:$to?$q');
}

void debugLogGuestLink(Evaluation evaluation) {
  if (kDebugMode) {
    // ignore: avoid_print
    print('[GuestInterview] ${guestInterviewLinkString(evaluation)}');
  }
}
