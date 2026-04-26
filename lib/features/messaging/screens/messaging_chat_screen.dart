import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/navigation_bar.dart';
import '../../../injection_container.dart';
import '../models/conversation_model.dart';
import '../providers/messaging_provider.dart';
import '../widgets/message_bubble.dart';

class MessagingChatScreen extends StatefulWidget {
  const MessagingChatScreen({super.key, required this.conversation});

  final ConversationModel conversation;

  @override
  State<MessagingChatScreen> createState() => _MessagingChatScreenState();
}

class _MessagingChatScreenState extends State<MessagingChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  String _meId = '';
  ParticipantModel _me =
      const ParticipantModel(id: '', name: 'You', avatarUrl: null, role: null);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid =
        await InjectionContainer.instance.authLocalDataSource.getUserId();
    if (!mounted) return;
    setState(() {
      _meId = uid ?? '';
      _me = ParticipantModel(
          id: _meId, name: 'You', avatarUrl: null, role: null);
    });
    await context.read<MessagingProvider>().loadMessages(widget.conversation);
    if (!mounted) return;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    scheduleMicrotask(() {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ParticipantModel? get _otherParticipant {
    if (widget.conversation.type == 'group') return null;
    if (_meId.isEmpty) return null;
    final others =
        widget.conversation.participants.where((p) => p.id != _meId).toList();
    if (others.isNotEmpty) return others.first;
    return widget.conversation.participants.isNotEmpty
        ? widget.conversation.participants.first
        : null;
  }

  String get _title {
    if (widget.conversation.type == 'group') {
      return widget.conversation.name ?? 'Group';
    }
    if (_meId.isEmpty) return '...';
    return _otherParticipant?.name ?? 'Direct Message';
  }

  String get _subtitle {
    if (widget.conversation.type == 'group') {
      final n = widget.conversation.participants.length;
      return '$n members';
    }
    return 'Online';
  }

  void _sendMessage() {
    final content = _text.text.trim();
    if (content.isEmpty) return;
    _text.clear();
    context.read<MessagingProvider>().sendMessage(
          conversation: widget.conversation,
          content: content,
          me: _me,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGroup = widget.conversation.type == 'group';
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final keyboardOpen = keyboardInset > 0;
    final listBottomPad = keyboardOpen ? (bottomSafe + 110.0) : (bottomSafe + 160.0);

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: isDark
          ? AppColors.primaryDark
          : const Color(0xFFF3F8FC),
      appBar: _buildAppBar(context, isDark, isGroup),
      // bottomNavigationBar does NOT automatically move above the keyboard on
      // iOS. We explicitly animate it using viewInsets.bottom so the typing
      // area never gets covered.
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: _BottomDock(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InputBar(
                controller: _text,
                onSend: _sendMessage,
                embedded: true,
              ),
              if (!keyboardOpen) const NavigationBarWidget(currentPath: '/messaging'),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F2940),
                    Color(0xFF0B1F31),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF7FBFF),
                    Color(0xFFEAF4FB),
                  ],
                ),
        ),
        child: Consumer<MessagingProvider>(
          builder: (context, p, _) {
            final list =
                p.messagesByConvId[widget.conversation.id] ?? const [];
            if (p.isLoading && list.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.cyan500),
              );
            }
            if (list.isEmpty) {
              return _buildEmptyState(context, isDark);
            }
            return ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(16, 16, 16, listBottomPad),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final m = list[i];
                final prev = i > 0 ? list[i - 1] : null;
                final next = i < list.length - 1 ? list[i + 1] : null;
                final isMe = m.senderId == _meId && _meId.isNotEmpty;

                final samePrev =
                    prev != null && prev.senderId == m.senderId;
                final sameNext =
                    next != null && next.senderId == m.senderId;

                final showSenderName =
                    isGroup && !isMe && !samePrev;
                final showTime = !sameNext ||
                    next.createdAt.difference(m.createdAt).inMinutes > 4;

                final showDateChip = prev == null ||
                    !_sameDay(prev.createdAt, m.createdAt);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDateChip) _DateChip(date: m.createdAt),
                    Padding(
                      padding: EdgeInsets.only(
                        top: samePrev ? 2 : 8,
                        bottom: sameNext ? 2 : 4,
                      ),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: MessageBubble(
                          message: m,
                          isMe: isMe,
                          showSenderName: showSenderName,
                          showTime: showTime,
                          tightTop: samePrev,
                          tightBottom: sameNext,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isDark, bool isGroup) {
    final other = _otherParticipant;
    final initial =
        (isGroup ? (widget.conversation.name ?? 'G') : _title).isNotEmpty
            ? (isGroup ? (widget.conversation.name ?? 'G') : _title)[0]
                .toUpperCase()
            : '?';

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.primaryDarker : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: AppColors.cyan500.withValues(alpha: 0.10),
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF12263A),
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                _Avatar(
                  initial: initial,
                  isGroup: isGroup,
                  url: other?.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF12263A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.cyan400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cyan500.withValues(alpha: 0.18),
                    AppColors.blue500.withValues(alpha: 0.18),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cyan500.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: AppColors.cyan400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Say hi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF12263A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start the conversation by sending the first message.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textCyan200.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.only(bottom: bottomSafe > 0 ? 0 : 8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryDarker.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.86),
            border: Border(
              top: BorderSide(
                color: AppColors.cyan500.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initial,
    required this.isGroup,
    this.url,
  });

  final String initial;
  final bool isGroup;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cyan500, AppColors.blue500],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan500.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialFallback(),
              )
            : _initialFallback(),
      ),
    );
  }

  Widget _initialFallback() {
    return Center(
      child: isGroup
          ? const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 20,
            )
          : Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
    );
  }
}

// ── Date chip ─────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    String label;
    if (diff == 0) {
      label = 'Today';
    } else if (diff == 1) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cyan500.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.cyan500.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textCyan200.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    this.embedded = false,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool embedded;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText && mounted) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      // Side padding only; bottom is handled by the NavigationBarWidget below.
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: widget.embedded
            ? null
            : BoxDecoration(
                color: isDark ? AppColors.primaryDarker : Colors.white,
                border: Border(
                  top: BorderSide(
                      color: AppColors.cyan500.withValues(alpha: 0.10)),
                ),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF12263A),
                ),
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => widget.onSend(),
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: TextStyle(
                      color: AppColors.textCyan200.withValues(alpha: 0.55)),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.55)
                      : const Color(0xFFF3F8FC),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color: AppColors.cyan500.withValues(alpha: 0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color: AppColors.cyan500.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color: AppColors.cyan500.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                gradient: _hasText
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.cyan500, AppColors.blue500],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.cyan500.withValues(alpha: 0.35),
                          AppColors.blue500.withValues(alpha: 0.35),
                        ],
                      ),
                borderRadius: BorderRadius.circular(23),
                boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: AppColors.cyan500.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: IconButton(
                onPressed: _hasText ? widget.onSend : null,
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
