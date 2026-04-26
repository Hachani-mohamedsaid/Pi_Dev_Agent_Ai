import 'dart:async';

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
  ParticipantModel _me = const ParticipantModel(id: '', name: 'You', avatarUrl: null, role: null);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = await InjectionContainer.instance.authLocalDataSource.getUserId();
    _meId = uid ?? '';
    _me = ParticipantModel(id: _meId, name: 'You', avatarUrl: null, role: null);
    if (!mounted) return;
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

  String get _title {
    if (widget.conversation.type == 'group') {
      return widget.conversation.name ?? 'Group';
    }
    final other = widget.conversation.participants.firstWhere(
      (p) => p.id != _meId,
      orElse: () => widget.conversation.participants.isNotEmpty
          ? widget.conversation.participants.first
          : _me,
    );
    return other.name;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.primaryDark : const Color(0xFFF3F8FC);
    final isGroup = widget.conversation.type == 'group';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: bg,
        foregroundColor: isDark ? Colors.white : const Color(0xFF12263A),
        elevation: 0,
      ),
      bottomNavigationBar: const NavigationBarWidget(currentPath: '/messaging'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<MessagingProvider>(
                builder: (context, p, _) {
                  final list = p.messagesByConvId[widget.conversation.id] ?? const [];
                  if (p.isLoading && list.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.cyan500),
                    );
                  }
                  return ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = list[i];
                      final isMe = m.senderId == _meId && _meId.isNotEmpty;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: MessageBubble(
                          message: m,
                          isMe: isMe,
                          showSenderName: isGroup,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _InputBar(
              controller: _text,
              onSend: () {
                final content = _text.text;
                _text.clear();
                context.read<MessagingProvider>().sendMessage(
                  conversation: widget.conversation,
                  content: content,
                  me: _me,
                );
                _scrollToBottom();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.primaryDarker,
        border: Border(top: BorderSide(color: AppColors.cyan500.withValues(alpha: 0.12))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Message…',
                hintStyle: TextStyle(color: AppColors.textCyan200.withValues(alpha: 0.55)),
                filled: true,
                fillColor: AppColors.primaryDark.withValues(alpha: 0.55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.cyan500.withValues(alpha: 0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.cyan500.withValues(alpha: 0.15)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            width: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.cyan500, AppColors.blue500],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                tooltip: 'Send',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

