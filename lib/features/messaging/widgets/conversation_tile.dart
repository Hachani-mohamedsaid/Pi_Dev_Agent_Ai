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
    return conversation.participants.isNotEmpty ? conversation.participants.first : null;
  }

  String get _title {
    if (conversation.type == 'group') {
      return (conversation.name ?? 'Group').trim().isEmpty ? 'Group' : conversation.name!;
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final other = _otherParticipant;
    final avatarUrl = conversation.type == 'direct' ? other?.avatarUrl : conversation.avatarUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.primaryMedium.withValues(alpha: 0.55) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.cyan500.withValues(alpha: 0.14) : const Color(0xFFE3F0F7),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.cyan500.withValues(alpha: 0.18),
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      _title.isNotEmpty ? _title.substring(0, 1).toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppColors.textWhite : const Color(0xFF12263A),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textCyan200.withValues(alpha: 0.65)
                          : const Color(0xFF5B7B92),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeLabel,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textCyan200.withValues(alpha: 0.55)
                        : const Color(0xFF7C97AA),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                if (conversation.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cyan500,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

