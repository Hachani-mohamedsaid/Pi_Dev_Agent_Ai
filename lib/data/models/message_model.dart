/// Message model for chat conversations.
/// Each message has a role (user or assistant) and content.
class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isLoading; // For displaying typing indicator

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });

  // Convert to API format for n8n webhook
  Map<String, String> toApiFormat() {
    return {'role': role, 'content': content};
  }

  // Create a copy with modified fields
  Message copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() => 'Message(role: $role, content: $content)';
}
