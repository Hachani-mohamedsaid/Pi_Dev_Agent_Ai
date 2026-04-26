import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/datasources/auth_local_data_source.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../services/messaging_api_service.dart';
import '../services/messaging_ws_service.dart';

class MessagingProvider extends ChangeNotifier {
  MessagingProvider({
    required MessagingApiService messagingApiService,
    required MessagingWsService messagingWsService,
    required AuthLocalDataSource authLocalDataSource,
  }) : _api = messagingApiService,
       _ws = messagingWsService,
       _auth = authLocalDataSource;

  final MessagingApiService _api;
  final MessagingWsService _ws;
  final AuthLocalDataSource _auth;

  bool isLoading = false;
  String? error;

  List<ConversationModel> conversations = [];
  final Map<String, List<ChatMessageModel>> messagesByConvId = {};
  int totalUnread = 0;
  String? activeConversationId;

  StreamSubscription? _wsSub;

  Future<void> init() async {
    final token = await _auth.getAccessToken();
    if (token == null || token.isEmpty) return;

    isLoading = true;
    error = null;
    notifyListeners();

    await _ws.connect();
    _wsSub ??= _ws.messageStream.listen(_onWsMessage);

    await Future.wait([refreshConversations(), refreshTotalUnread()]);

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshConversations() async {
    final list = await _api.getConversations();
    conversations = list;
    notifyListeners();
  }

  Future<void> refreshTotalUnread() async {
    totalUnread = await _api.getTotalUnread();
    notifyListeners();
  }

  Future<void> loadMessages(ConversationModel conversation) async {
    activeConversationId = conversation.id;
    _ws.joinConversation(conversation.id);
    notifyListeners();

    final msgs = await _api.getMessages(conversation.id);
    messagesByConvId[conversation.id] = msgs;
    notifyListeners();

    await markRead(conversation.id);
  }

  Future<void> markRead(String conversationId) async {
    _ws.markRead(conversationId);
    await _api.markRead(conversationId);
    // refresh totals optimistically
    await refreshConversations();
    await refreshTotalUnread();
  }

  void sendMessage({
    required ConversationModel conversation,
    required String content,
    required ParticipantModel me,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final optimistic = ChatMessageModel(
      id: 'local_${now.microsecondsSinceEpoch}',
      conversationId: conversation.id,
      senderId: me.id,
      senderName: me.name,
      senderAvatar: me.avatarUrl,
      content: trimmed,
      createdAt: now,
      readBy: [me.id],
    );

    final list = (messagesByConvId[conversation.id] ?? <ChatMessageModel>[]);
    messagesByConvId[conversation.id] = [...list, optimistic];

    _ws.sendMessage(conversation.id, trimmed);

    // update lastMessage locally
    conversations = conversations.map((c) {
      if (c.id != conversation.id) return c;
      return ConversationModel(
        id: c.id,
        type: c.type,
        name: c.name,
        avatarUrl: c.avatarUrl,
        participants: c.participants,
        lastMessage: LastMessageModel(
          content: trimmed,
          senderId: me.id,
          senderName: me.name,
          createdAt: now,
        ),
        unreadCount: 0,
      );
    }).toList();

    notifyListeners();
  }

  Future<ConversationModel?> createDirect(String participantId) async {
    final conv = await _api.getOrCreateDirect(participantId);
    if (conv == null) return null;
    conversations = [conv, ...conversations.where((c) => c.id != conv.id)];
    notifyListeners();
    return conv;
  }

  Future<ConversationModel?> createGroup(String name, List<String> participantIds) async {
    final conv = await _api.createGroup(name, participantIds);
    if (conv == null) return null;
    conversations = [conv, ...conversations.where((c) => c.id != conv.id)];
    notifyListeners();
    return conv;
  }

  Future<List<ParticipantModel>> searchUsers(String q) => _api.searchUsers(q);

  void _onWsMessage(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'new_message') {
      final convId = data['conversationId']?.toString() ?? '';
      final msgJson = data['message'];
      if (convId.isEmpty || msgJson is! Map) return;
      final msg = ChatMessageModel.fromJson(msgJson.cast<String, dynamic>());
      final list = messagesByConvId[convId] ?? <ChatMessageModel>[];
      messagesByConvId[convId] = [...list, msg];

      // bump unread if not active
      if (activeConversationId != convId) {
        conversations = conversations.map((c) {
          if (c.id != convId) return c;
          return ConversationModel(
            id: c.id,
            type: c.type,
            name: c.name,
            avatarUrl: c.avatarUrl,
            participants: c.participants,
            lastMessage: LastMessageModel(
              content: msg.content,
              senderId: msg.senderId,
              senderName: msg.senderName,
              createdAt: msg.createdAt,
            ),
            unreadCount: c.unreadCount + 1,
          );
        }).toList();
        totalUnread += 1;
      } else {
        // active conversation: mark read automatically (best-effort)
        _ws.markRead(convId);
      }
      notifyListeners();
    }

    if (type == 'read_receipt') {
      final convId = data['conversationId']?.toString() ?? '';
      final userId = data['userId']?.toString() ?? '';
      if (convId.isEmpty || userId.isEmpty) return;
      final list = messagesByConvId[convId] ?? <ChatMessageModel>[];
      messagesByConvId[convId] = list
          .map((m) => m.senderId == userId ? m : m)
          .toList();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsSub = null;
    _ws.close();
    super.dispose();
  }
}

