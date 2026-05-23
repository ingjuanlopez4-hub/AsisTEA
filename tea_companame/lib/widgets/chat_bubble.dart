import 'package:flutter/material.dart';
import '../config/theme.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime? timestamp;
  final bool isTyping;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.timestamp,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isDark),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.bubbleUser
                    : (isDark
                        ? AppTheme.bubbleAssistantDark
                        : AppTheme.bubbleAssistant),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: isTyping ? _buildTypingIndicator() : _buildMessageContent(isDark),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(isDark),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? AppTheme.primaryGreen
          : (isDark ? AppTheme.accentWarmDark : AppTheme.accentWarm),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: isUser ? Colors.white : (isDark ? Colors.white : Colors.white),
      ),
    );
  }

  Widget _buildMessageContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(
            fontSize: 15,
            color: isUser ? Colors.white : (isDark ? Colors.white : AppTheme.textPrimary),
            height: 1.4,
          ),
        ),
        if (timestamp != null) ...[
          const SizedBox(height: 4),
          Text(
            _formatTime(timestamp),
            style: TextStyle(
              fontSize: 11,
              color: isUser
                  ? Colors.white.withOpacity(0.7)
                  : (isDark ? Colors.grey[400] : AppTheme.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 8,
          height: 8,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.textSecondary,
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Escribiendo...',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
