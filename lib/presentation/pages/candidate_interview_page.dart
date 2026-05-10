import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/evaluation.dart';
import '../../data/services/candidate_interview_api_service.dart';

Color _primaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textWhite
      : const Color(0xFF12263A);
}

Color _secondaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textCyan200
      : const Color(0xFF5B7B92);
}

/// Chat d’entretien assisté : appelle Nest `POST /interviews/start` puis
/// `POST /interviews/:sessionId/message` (JWT).
class CandidateInterviewPage extends StatefulWidget {
  const CandidateInterviewPage({super.key, this.evaluation});

  final Evaluation? evaluation;

  @override
  State<CandidateInterviewPage> createState() => _CandidateInterviewPageState();
}

class _ChatLine {
  _ChatLine({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}

class _CandidateInterviewPageState extends State<CandidateInterviewPage> {
  final _api = CandidateInterviewApiService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _lines = <_ChatLine>[];

  String? _sessionId;
  bool _starting = true;
  bool _sending = false;
  bool _completing = false;
  String? _error;

  String get _title =>
      widget.evaluation?.candidateName?.trim().isNotEmpty == true
      ? widget.evaluation!.candidateName!.trim()
      : 'Entretien assisté';

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (widget.evaluation == null) {
      setState(() {
        _starting = false;
        _error = 'Aucune candidature sélectionnée.';
      });
      return;
    }

    final e = widget.evaluation!;
    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final r = await _api.startSession(
        evaluationId: e.evaluationId,
        candidateName: e.candidateName,
        jobTitle: e.jobTitle,
        jobId: e.jobId,
      );
      if (!mounted) return;
      final first = r.assistantMessage.trim().isEmpty
          ? 'Bonjour. Posez votre première question ou invitez le candidat à se présenter.'
          : r.assistantMessage.trim();
      setState(() {
        _sessionId = r.sessionId;
        _lines.add(_ChatLine(isUser: false, text: first));
        _starting = false;
      });
      _scrollToBottom();
    } on InterviewApiException catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.message;
        _starting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Connexion impossible. Vérifiez le backend (routes /interviews) et votre session.';
        _starting = false;
      });
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

  Future<void> _send() async {
    final text = _input.text.trim();
    final sid = _sessionId;
    if (text.isEmpty || sid == null || _sending) return;

    setState(() {
      _lines.add(_ChatLine(isUser: true, text: text));
      _input.clear();
      _sending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final reply = await _api.sendMessage(sid, text);
      if (!mounted) return;
      setState(() {
        _lines.add(_ChatLine(isUser: false, text: reply));
        _sending = false;
      });
      _scrollToBottom();
    } on InterviewApiException catch (err) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = err.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  Future<void> _complete() async {
    final sid = _sessionId;
    if (sid == null || _completing) return;

    setState(() => _completing = true);
    final summary = await _api.completeSession(sid);
    if (!mounted) return;
    setState(() => _completing = false);

    if (summary != null && summary.isNotEmpty) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).brightness == Brightness.dark
              ? const Color(0xFF142E42)
              : const Color(0xFFF9FCFF),
          title: Text('Synthèse', style: TextStyle(color: _primaryText(ctx))),
          content: SingleChildScrollView(
            child: Text(
              summary,
              style: TextStyle(color: _secondaryText(ctx), height: 1.4),
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
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entretien terminé.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FCFF), Color(0xFFEAF4FB), Color(0xFFF3F8FC)],
          );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0f2940)
          : const Color(0xFFF3F8FC),
      body: Container(
        decoration: BoxDecoration(gradient: pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        color: _primaryText(context),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryText(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Entretien assisté (IA)',
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondaryText(
                                context,
                              ).withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_sessionId != null && !_starting)
                      TextButton(
                        onPressed: _completing ? null : _complete,
                        child: _completing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Terminer'),
                      ),
                  ],
                ),
              ),
              if (widget.evaluation?.jobTitle != null &&
                  widget.evaluation!.jobTitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.evaluation!.jobTitle!,
                      style: TextStyle(
                        color: _secondaryText(context).withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Material(
                    color: const Color(0xFF7f1d1d).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _starting
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.cyan400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Préparation de l’entretien…',
                              style: TextStyle(color: _secondaryText(context)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                          final line = _lines[i];
                          return _Bubble(line: line);
                        },
                      ),
              ),
              if (!_starting && _sessionId != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.95)
                        : const Color(0xFFF9FCFF),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.textCyan200.withValues(alpha: 0.1)
                            : const Color(0xFFC7DDE9),
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
                          style: TextStyle(color: _primaryText(context)),
                          decoration: InputDecoration(
                            hintText: 'Votre message…',
                            hintStyle: TextStyle(
                              color: _secondaryText(
                                context,
                              ).withValues(alpha: 0.7),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.primaryDarker.withValues(alpha: 0.9)
                                : const Color(0xFFFFFFFF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.cyan400.withValues(alpha: 0.2),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.textCyan200.withValues(
                                        alpha: 0.12,
                                      )
                                    : const Color(0xFFC7DDE9),
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
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _sending ? null : _send,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.line});

  final _ChatLine line;

  @override
  Widget build(BuildContext context) {
    final user = line.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: user
              ? AppColors.cyan500.withValues(alpha: 0.25)
              : (isDark
                    ? AppColors.primaryDarker.withValues(alpha: 0.95)
                    : const Color(0xFFFFFFFF)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(user ? 16 : 4),
            bottomRight: Radius.circular(user ? 4 : 16),
          ),
          border: Border.all(
            color: user
                ? AppColors.cyan400.withValues(alpha: 0.35)
                : (isDark
                      ? AppColors.textCyan200.withValues(alpha: 0.12)
                      : const Color(0xFFC7DDE9)),
          ),
        ),
        child: Text(
          line.text,
          style: TextStyle(
            color: user ? AppColors.textWhite : _primaryText(context),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
