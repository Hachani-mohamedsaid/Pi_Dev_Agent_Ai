import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showSenderName,
  });

  final ChatMessageModel message;
  final bool isMe;
  final bool showSenderName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe
        ? null
        : (isDark ? AppColors.primaryMedium : const Color(0xFF1A3A52));
    final bubbleGradient = isMe
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cyan500, AppColors.blue500],
          )
        : null;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    final h = message.createdAt.hour.toString().padLeft(2, '0');
    final m = message.createdAt.minute.toString().padLeft(2, '0');
    final time = '$h:$m';

    return Column(
      crossAxisAlignment: align,
      children: [
        if (showSenderName && !isMe)
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 3),
            child: Text(
              message.senderName,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textCyan200.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            gradient: bubbleGradient,
            borderRadius: radius,
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textCyan200.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

