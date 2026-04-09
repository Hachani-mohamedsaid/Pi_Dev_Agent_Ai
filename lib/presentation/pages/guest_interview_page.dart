import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/evaluation.dart';
import '../../data/services/candidate_interview_api_service.dart';
import '../../data/services/guest_interview_api_service.dart';
import '../../features/guest_interview/proctoring/guest_proctoring_coordinator.dart';

/// Page **publique** pour le candidat : `/guest-interview?...` sans compte.
///
/// Si `guestToken` est présent (`?token=`), tente `POST /interviews/guest/start` puis chat réel.
/// Sinon (ou si l’API échoue) : aperçu statique + proctoring.
class GuestInterviewPage extends StatefulWidget {
  const GuestInterviewPage({
    super.key,
    required this.evaluation,
    this.guestToken,
    this.prefilledSessionId,
  });

  final Evaluation evaluation;
  final String? guestToken;
  final String? prefilledSessionId;

  @override
  State<GuestInterviewPage> createState() => _GuestInterviewPageState();
}

enum _GuestPhase { consent, interview }

class _GuestInterviewPageState extends State<GuestInterviewPage>
    with WidgetsBindingObserver {
  _GuestPhase _phase = _GuestPhase.consent;
  bool _honesty = false;
  bool _cameraPolicy = false;
  bool _starting = false;
  GuestProctoringCoordinator? _coordinator;
  bool _lifecycleAttached = false;

  /// Chat connecté au backend (jeton invité + start OK).
  bool _liveMode = false;

  /// Jeton présent mais `/interviews/guest/start` a échoué.
  bool _staticFallback = false;
  String? _apiFallbackHint;

  final _guestApi = GuestInterviewApiService();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  String? _chatSessionId;
  final _lines = <_GuestLine>[];
  bool _sending = false;
  bool _completing = false;

  String get _name {
    final n = widget.evaluation.candidateName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Candidat';
  }

  String get _job {
    final j = widget.evaluation.jobTitle?.trim();
    if (j != null && j.isNotEmpty) return j;
    return 'le poste proposé';
  }

  String? get _trimmedGuestToken {
    final t = widget.guestToken?.trim();
    return (t != null && t.isNotEmpty) ? t : null;
  }

  List<_GuestLine> get _staticScript => [
        _GuestLine(
          fromRecruiterBot: true,
          text:
              'Bonjour $_name,\n\n'
              'Vous avez été invité(e) à passer un aperçu d’entretien pour : $_job.\n\n'
              'Sans jeton d’invitation serveur dans le lien, cette page reste en démonstration. '
              'Avec un lien signé (`token=`), l’entretien se connecte à l’IA.',
        ),
        _GuestLine(
          fromRecruiterBot: false,
          text:
              'Pourriez-vous vous présenter en quelques phrases et dire ce qui vous attire dans ce poste ?',
        ),
        _GuestLine(
          fromRecruiterBot: true,
          text:
              '(Exemple) Je suis à l’aise avec les projets collaboratifs et j’aimerais contribuer '
              'à un produit utilisé au quotidien…',
        ),
        _GuestLine(
          fromRecruiterBot: false,
          text:
              'Comment géreriez-vous un désaccord technique avec un collègue tout en respectant les délais ?',
        ),
        _GuestLine(
          fromRecruiterBot: true,
          text:
              '(Exemple) J’écoute les arguments, je propose un petit atelier ou une doc partagée, '
              'et on tranche avec le lead si besoin.',
        ),
      ];

  @override
  void dispose() {
    if (_lifecycleAttached) {
      WidgetsBinding.instance.removeObserver(this);
    }
    unawaited(_coordinator?.stop() ?? Future.value());
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _coordinator?.batcher.record(type: 'app_backgrounded');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _onStartInterview() async {
    if (!_honesty || !_cameraPolicy || _starting) return;
    setState(() => _starting = true);

    final token = _trimmedGuestToken;
    final e = widget.evaluation;
    final hintSid = widget.prefilledSessionId?.trim();
    final proctorSid = (hintSid != null && hintSid.isNotEmpty)
        ? hintSid
        : const Uuid().v4();

    Future<void> startProctoring(String sid, String? gt) async {
      final coord = GuestProctoringCoordinator(
        sessionId: sid,
        guestToken: gt,
      );
      coord.recordHonestyAttested();
      coord.recordSessionProctoringStarted();
      await coord.start();
      if (!mounted) return;
      if (!_lifecycleAttached) {
        WidgetsBinding.instance.addObserver(this);
        _lifecycleAttached = true;
      }
      setState(() => _coordinator = coord);
    }

    if (token != null) {
      try {
        final r = await _guestApi.startSession(
          guestToken: token,
          evaluationId: e.evaluationId,
          candidateName: e.candidateName,
          jobTitle: e.jobTitle,
          jobId: e.jobId,
          existingSessionIdHint:
              (hintSid != null && hintSid.isNotEmpty) ? hintSid : null,
        );
        if (!mounted) return;

        final first = r.assistantMessage.trim().isEmpty
            ? 'Bonjour $_name. Je suis l’assistant d’entretien. Commençons par une brève présentation de votre parcours.'
            : r.assistantMessage.trim();

        await startProctoring(r.sessionId, token);

        if (!mounted) return;
        setState(() {
          _starting = false;
          _phase = _GuestPhase.interview;
          _liveMode = true;
          _staticFallback = false;
          _apiFallbackHint = null;
          _chatSessionId = r.sessionId;
          _lines
            ..clear()
            ..add(_GuestLine(fromRecruiterBot: true, text: first));
        });
        _scrollToBottom();
        return;
      } on InterviewApiException catch (err) {
        if (mounted) {
          setState(() {
            _apiFallbackHint = err.message;
            _staticFallback = true;
            _liveMode = false;
            _lines
              ..clear()
              ..addAll(_staticScript);
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _apiFallbackHint =
                'Connexion impossible au serveur d’entretien invité.';
            _staticFallback = true;
            _liveMode = false;
            _lines
              ..clear()
              ..addAll(_staticScript);
          });
        }
      }
      await startProctoring(proctorSid, token);
    } else {
      await startProctoring(proctorSid, null);
      if (!mounted) return;
      setState(() {
        _liveMode = false;
        _staticFallback = false;
        _lines
          ..clear()
          ..addAll(_staticScript);
      });
    }

    if (!mounted) return;
    setState(() {
      _starting = false;
      _phase = _GuestPhase.interview;
    });
  }

  Future<void> _sendLive() async {
    final text = _input.text.trim();
    final sid = _chatSessionId;
    final token = _trimmedGuestToken;
    if (!_liveMode || text.isEmpty || sid == null || token == null || _sending) {
      return;
    }

    setState(() {
      _lines.add(_GuestLine(fromRecruiterBot: false, text: text));
      _input.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await _guestApi.sendMessage(token, sid, text);
      if (!mounted) return;
      setState(() {
        _lines.add(_GuestLine(fromRecruiterBot: true, text: reply));
        _sending = false;
      });
      _scrollToBottom();
    } on InterviewApiException catch (err) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _lines.add(
          _GuestLine(
            fromRecruiterBot: true,
            text: 'Désolé, une erreur est survenue : ${err.message}',
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  Future<void> _onFinish() async {
    final token = _trimmedGuestToken;
    final sid = _chatSessionId;

    if (_liveMode && sid != null && token != null) {
      setState(() => _completing = true);
      final summary = await _guestApi.completeSession(token, sid);
      if (!mounted) return;
      setState(() => _completing = false);

      if (summary != null && summary.isNotEmpty) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF142E42),
            title: const Text(
              'Synthèse',
              style: TextStyle(color: AppColors.textWhite),
            ),
            content: SingleChildScrollView(
              child: Text(
                summary,
                style: const TextStyle(color: AppColors.textCyan200, height: 1.4),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }

    await _coordinator?.stop();
    if (!mounted) return;
    setState(() => _coordinator = null);

    final id = widget.evaluation.evaluationId?.trim() ?? '—';
    final report = StringBuffer()
      ..writeln('Entretien — $_job')
      ..writeln('Candidat : $_name')
      ..writeln('Réf. évaluation : $id')
      ..writeln(_liveMode ? '(session connectée au serveur)' : '(aperçu / démo)')
      ..writeln()
      ..writeln(
        'Les événements proctoring sont envoyés si l’endpoint '
        'POST …/guest/.../proctoring-events est configuré.',
      );

    if (!context.mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF142E42),
        title: const Text(
          'Merci',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _liveMode
                    ? 'Merci. Votre entretien a été enregistré côté serveur si le backend est actif.'
                    : 'Merci d’avoir parcouru cet aperçu. Pour un entretien IA réel, utilisez un lien '
                        'contenant le paramètre token= fourni par le recruteur.',
                style: TextStyle(
                  color: AppColors.textCyan200.withValues(alpha: 0.95),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                report.toString(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report.toString()));
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'Texte copié — vous pouvez l’envoyer au recruteur par e-mail.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Copier pour le recruteur'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _GuestPhase.consent) {
      return _buildConsent(context);
    }
    return _buildInterview(context);
  }

  Widget _buildConsent(BuildContext context) {
    final camHint = kIsWeb
        ? 'Sur le web, nous enregistrons uniquement les changements d’onglet / de fenêtre (pas de vidéo).'
        : 'Sur téléphone, la caméra frontale sert à détecter l’absence prolongée de visage ou plusieurs visages. '
            'Aucune vidéo n’est envoyée au serveur, seulement des événements textuels.';

    final tokenNote = _trimmedGuestToken == null
        ? 'Ce lien ne contient pas de jeton serveur (`token=`) : après le démarrage, l’entretien restera en mode démo.'
        : 'Ce lien contient un jeton : après acceptation, connexion à l’IA sur le serveur si la route '
            '`POST /interviews/guest/start` est disponible.';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f2940),
              Color(0xFF1a3a52),
              Color(0xFF0f2940),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Avant de commencer',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tokenNote,
                  style: TextStyle(
                    color: AppColors.cyan400.withValues(alpha: 0.95),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cet entretien peut être complété par des signaux techniques pour limiter la fraude '
                  '(durées, visage sur appareil mobile, activité de l’onglet sur le web). '
                  'Les données sont minimisées ; pas d’enregistrement vidéo envoyé au recruteur dans cette version.',
                  style: TextStyle(
                    color: AppColors.textCyan200.withValues(alpha: 0.92),
                    height: 1.45,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  camHint,
                  style: TextStyle(
                    color: AppColors.textCyan200.withValues(alpha: 0.85),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: _honesty,
                  onChanged: (v) => setState(() => _honesty = v ?? false),
                  activeColor: AppColors.cyan500,
                  title: const Text(
                    'Je réponds seul, sans aide d’une autre personne ni d’une IA externe.',
                    style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  value: _cameraPolicy,
                  onChanged: (v) => setState(() => _cameraPolicy = v ?? false),
                  activeColor: AppColors.cyan500,
                  title: Text(
                    kIsWeb
                        ? 'J’accepte le suivi léger de l’onglet / de la fenêtre pendant la session.'
                        : 'J’accepte l’activation de la caméra frontale pour la détection de visage (aperçu local).',
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 14,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed:
                      (_honesty && _cameraPolicy && !_starting) ? _onStartInterview : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan500,
                    foregroundColor: const Color(0xFF0a1628),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _starting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Commencer l’entretien'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterview(BuildContext context) {
    final preview = _coordinator?.cameraPreviewOverlay;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0f2940),
              Color(0xFF1a3a52),
              Color(0xFF0f2940),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      color: AppColors.cyan400,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _job,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textWhite,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _liveMode
                                ? 'Entretien IA (connecté) — $_name'
                                : 'Entretien invité — $_name',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textCyan200.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _completing ? null : () => _onFinish(),
                      child: _completing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Terminer'),
                    ),
                  ],
                ),
              ),
              if (_staticFallback && _apiFallbackHint != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350f).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textCyan200.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Mode démo : l’IA invitée n’a pas répondu (${_apiFallbackHint!.length > 180 ? "${_apiFallbackHint!.substring(0, 180)}…" : _apiFallbackHint}).',
                        style: TextStyle(
                          color: AppColors.textCyan200.withValues(alpha: 0.95),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textCyan200.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _liveMode
                          ? 'Conversation en direct avec le serveur. Proctoring actif (événements vers …/proctoring-events).'
                          : kIsWeb
                              ? 'Proctoring actif : onglet / fenêtre. Pas de saisie tant que le lien ne contient pas `token=` ou que l’API invité est indisponible.'
                              : 'Proctoring actif : caméra (visage) + arrière-plan. Mode démo sans champ de saisie si pas de `token=` dans l’URL.',
                      style: TextStyle(
                        color: AppColors.textCyan200.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: _lines.length + (_sending ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (_sending && i == _lines.length) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.cyan400,
                                ),
                              ),
                            ),
                          );
                        }
                        return _GuestBubble(line: _lines[i]);
                      },
                    ),
                    if (preview != null)
                      Positioned(
                        top: 8,
                        right: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.cyan400.withValues(alpha: 0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: preview,
                        ),
                      ),
                  ],
                ),
              ),
              if (_liveMode)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.95),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.textCyan200.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          style: const TextStyle(color: AppColors.textWhite),
                          decoration: InputDecoration(
                            hintText: 'Votre réponse…',
                            hintStyle: TextStyle(
                              color: AppColors.textCyan200.withValues(alpha: 0.45),
                            ),
                            filled: true,
                            fillColor:
                                AppColors.primaryDarker.withValues(alpha: 0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.cyan400.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    AppColors.textCyan200.withValues(alpha: 0.12),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppColors.cyan400,
                                width: 1.2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendLive(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _sending ? null : _sendLive,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.cyan500,
                          foregroundColor: const Color(0xFF0a1628),
                          padding: const EdgeInsets.all(14),
                          shape: const CircleBorder(),
                        ),
                        child: const Icon(LucideIcons.send, size: 20),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'Pas de saisie en mode démo. Ajoutez `token=` à l’URL (lien émis par le backend) pour chatter avec l’IA.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textCyan200.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestLine {
  _GuestLine({required this.fromRecruiterBot, required this.text});
  final bool fromRecruiterBot;
  final String text;
}

class _GuestBubble extends StatelessWidget {
  const _GuestBubble({required this.line});

  final _GuestLine line;

  @override
  Widget build(BuildContext context) {
    final left = line.fromRecruiterBot;
    return Align(
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: left
              ? AppColors.primaryDarker.withValues(alpha: 0.95)
              : AppColors.cyan500.withValues(alpha: 0.22),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(left ? 4 : 16),
            bottomRight: Radius.circular(left ? 16 : 4),
          ),
          border: Border.all(
            color: left
                ? AppColors.textCyan200.withValues(alpha: 0.12)
                : AppColors.cyan400.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          line.text,
          style: TextStyle(
            color: left ? AppColors.textCyan200 : AppColors.textWhite,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
