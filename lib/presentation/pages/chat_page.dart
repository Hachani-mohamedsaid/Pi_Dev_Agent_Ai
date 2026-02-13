import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../presentation/state/chat_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();

    // Initialize chat on first load (French welcome for n8n AI assistant)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initializeChat(
        welcomeMessage: 'Bonjour ! Comment puis-je vous aider aujourd\'hui ?',
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() => _isComposing = false);

    // Send message through provider
    await context.read<ChatProvider>().sendMessage(text);

    // Scroll to bottom after response
    Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
  }

  void _onMessageChanged(String value) {
    setState(() => _isComposing = value.trim().isNotEmpty);
  }

  void _retryMessage() {
    context.read<ChatProvider>().retryLastMessage();
    Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation?'),
        content: const Text(
          'Are you sure you want to clear all messages? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearMessages();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Assistant'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: _clearConversation,
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                // Auto scroll when new messages arrive
                if (chatProvider.messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isUser = message.role == 'user';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: message.isLoading
                              ? _buildTypingIndicator()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _formatTime(message.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isUser
                                              ? Colors.white70
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Error Message
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              if (chatProvider.error != null) {
                return Container(
                  color: Colors.red[50],
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(LucideIcons.alertCircle, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Error',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            Text(
                              chatProvider.error!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _retryMessage();
                          context.read<ChatProvider>().clearError();
                        },
                        child: const Text('Retry'),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () =>
                            context.read<ChatProvider>().clearError(),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Pending Email Confirmation Bar
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              if (!chatProvider.hasPendingEmail) return const SizedBox.shrink();

              final pending = chatProvider.pendingEmail!;
              final to = pending['to'] ?? '';

              return Container(
                color: Colors.blue[50],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Envoyer un e‑mail à $to ?',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await context
                            .read<ChatProvider>()
                            .confirmPendingEmail();
                        Future.delayed(
                          const Duration(milliseconds: 200),
                          _scrollToBottom,
                        );
                      },
                      child: const Text('Envoyer'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<ChatProvider>().cancelPendingEmail();
                        Future.delayed(
                          const Duration(milliseconds: 200),
                          _scrollToBottom,
                        );
                      },
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Input Area
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _onMessageChanged,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    enabled: !context.watch<ChatProvider>().isLoading,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (_isComposing &&
                          !context.read<ChatProvider>().isLoading) {
                        _handleSendMessage();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, _) {
                    return FloatingActionButton(
                      onPressed: _isComposing && !chatProvider.isLoading
                          ? _handleSendMessage
                          : null,
                      mini: true,
                      backgroundColor: _isComposing && !chatProvider.isLoading
                          ? Colors.blue
                          : Colors.grey[300],
                      child: Icon(
                        LucideIcons.send,
                        color: _isComposing && !chatProvider.isLoading
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedOpacity(
            opacity: 0.7,
            duration: Duration(milliseconds: 600 + (index * 200)),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
