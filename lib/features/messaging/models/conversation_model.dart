class ConversationModel {
  final String id;
  final String type; // 'direct' | 'group'
  final String? name;
  final String? avatarUrl;
  final List<ParticipantModel> participants;
  final LastMessageModel? lastMessage;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.type,
    required this.name,
    required this.avatarUrl,
    required this.participants,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: (json['type'] ?? 'direct').toString(),
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      participants: ((json['participants'] as List?) ?? const [])
          .map((e) => ParticipantModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      lastMessage: json['lastMessage'] is Map
          ? LastMessageModel.fromJson((json['lastMessage'] as Map).cast<String, dynamic>())
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'avatarUrl': avatarUrl,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
    };
  }
}

class ParticipantModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? role;

  const ParticipantModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.role,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'role': role,
      };
}

class LastMessageModel {
  final String content;
  final String senderId;
  final String senderName;
  final DateTime createdAt;

  const LastMessageModel({
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    return LastMessageModel(
      content: (json['content'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderName: (json['senderName'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'content': content,
        'senderId': senderId,
        'senderName': senderName,
        'createdAt': createdAt.toIso8601String(),
      };
}

