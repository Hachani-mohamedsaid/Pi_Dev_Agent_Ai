import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showSenderName,
    this.showTime = true,
    this.tightTop = false,
    this.tightBottom = false,
  });

  final ChatMessageModel message;
  final bool isMe;
  final bool showSenderName;
  final bool showTime;
  final bool tightTop;
  final bool tightBottom;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final bubbleColor = isMe
        ? null
        : (isDark
            ? AppColors.primaryMedium.withValues(alpha: 0.85)
            : Colors.white);
    final bubbleGradient = isMe
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cyan500, AppColors.blue500],
          )
        : null;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(isMe ? 20 : (tightTop ? 6 : 20)),
      topRight: Radius.circular(isMe ? (tightTop ? 6 : 20) : 20),
      bottomLeft: Radius.circular(isMe ? 20 : (tightBottom ? 6 : 6)),
      bottomRight: Radius.circular(isMe ? (tightBottom ? 6 : 6) : 20),
    );

    final h = message.createdAt.hour.toString().padLeft(2, '0');
    final m = message.createdAt.minute.toString().padLeft(2, '0');
    final time = '$h:$m';

    final textColor = isMe
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF12263A));

    return Column(
      crossAxisAlignment: align,
      children: [
        if (showSenderName && !isMe)
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 4),
            child: Text(
              message.senderName,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.cyan400,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            gradient: bubbleGradient,
            borderRadius: radius,
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: AppColors.cyan500.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
            border: !isMe
                ? Border.all(
                    color: AppColors.cyan500.withValues(alpha: 0.10),
                  )
                : null,
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: textColor,
              fontSize: 14.5,
              height: 1.35,
            ),
          ),
        ),
        if (showTime) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textCyan200.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
