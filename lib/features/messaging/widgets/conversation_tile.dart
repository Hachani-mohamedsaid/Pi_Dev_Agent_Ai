import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/conversation_model.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.meId,
    required this.onTap,
  });

  final ConversationModel conversation;
  final String meId;
  final VoidCallback onTap;

  ParticipantModel? get _otherParticipant {
    if (conversation.type != 'direct') return null;
    for (final p in conversation.participants) {
      if (p.id != meId) return p;
    }
    return conversation.participants.isNotEmpty
        ? conversation.participants.first
        : null;
  }

  String get _title {
    if (conversation.type == 'group') {
      return (conversation.name ?? 'Group').trim().isEmpty
          ? 'Group'
          : conversation.name!;
    }
    return _otherParticipant?.name ?? 'Direct Message';
  }

  String get _subtitle {
    final lm = conversation.lastMessage;
    if (lm == null) return 'Say hi';
    return lm.content;
  }

  String get _timeLabel {
    final dt = conversation.lastMessage?.createdAt;
    if (dt == null) return '';
    final now = DateTime.now();
    final isToday = now.year == dt.year &&
        now.month == dt.month &&
        now.day == dt.day;
    if (isToday) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final yesterday = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (yesterday == 1) return 'Yesterday';
    if (yesterday < 7) {
      const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return wd[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final other = _otherParticipant;
    final avatarUrl =
        conversation.type == 'direct' ? other?.avatarUrl : conversation.avatarUrl;
    final hasUnread = conversation.unreadCount > 0;
    final isGroup = conversation.type == 'group';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primaryMedium.withValues(alpha: 0.55)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnread
                  ? AppColors.cyan500.withValues(alpha: 0.35)
                  : (isDark
                      ? AppColors.cyan500.withValues(alpha: 0.10)
                      : const Color(0xFFE3F0F7)),
              width: hasUnread ? 1.2 : 1,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(
                title: _title,
                avatarUrl: avatarUrl,
                isGroup: isGroup,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF12263A),
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeLabel,
                          style: TextStyle(
                            color: hasUnread
                                ? AppColors.cyan400
                                : (isDark
                                    ? AppColors.textCyan200
                                        .withValues(alpha: 0.55)
                                    : const Color(0xFF7C97AA)),
                            fontSize: 11,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasUnread
                                  ? (isDark
                                      ? Colors.white.withValues(alpha: 0.88)
                                      : const Color(0xFF12263A))
                                  : (isDark
                                      ? AppColors.textCyan200
                                          .withValues(alpha: 0.65)
                                      : const Color(0xFF5B7B92)),
                              fontSize: 13,
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasUnread)
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.cyan500,
                                  AppColors.blue500,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cyan500
                                      .withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : '${conversation.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
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

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.title,
    required this.avatarUrl,
    required this.isGroup,
  });

  final String title;
  final String? avatarUrl;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cyan500, AppColors.blue500],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan500.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cyan500, AppColors.blue500],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isGroup
            ? const Icon(
                Icons.groups_rounded,
                color: Colors.white,
                size: 22,
              )
            : Text(
                title.isNotEmpty ? title.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }
}
