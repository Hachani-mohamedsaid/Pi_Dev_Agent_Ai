# Quick Start: N8N Chat Implementation

This document provides a quick reference for using the n8n chat integration.

## 1. File Locations (Reference)

| File | Path | Purpose |
|------|------|---------|
| Message Model | `lib/data/models/message_model.dart` | Defines message structure |
| Chat Service | `lib/data/services/n8n_chat_service.dart` | HTTP client for n8n webhook |
| Chat Provider | `lib/presentation/state/chat_provider.dart` | State management |
| Chat Page | `lib/presentation/pages/chat_page.dart` | UI screen |
| App Setup | `lib/app/app.dart` | Provider wrap (already updated) |
| Routing | `lib/core/routing/app_router.dart` | Added /chat route (already updated) |
| Dependency Injection | `lib/injection_container.dart` | DI setup (already updated) |
| Dependencies | `pubspec.yaml` | Provider added (already updated) |

## 2. Quick Setup (One-Time)

```bash
# 1. Get dependencies
flutter pub get

# 2. Run the app
flutter run

# 3. Navigate to chat page from home screen
# Click the navigation button that leads to /chat route
```

## 3. Access the Chat Page

### From Home Screen Button
```dart
// Add this button to your home_screen.dart or wherever
ElevatedButton.icon(
  onPressed: () => context.push('/chat'),
  icon: const Icon(Icons.chat),
  label: const Text('Chat'),
)
```

### From Custom Navigation
```dart
// Using go_router (recommended)
context.push('/chat');

// Using Navigator (alternative)
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const ChatPage())
);
```

## 4. Using ChatProvider in Your Widgets

### Read Message History
```dart
final messages = context.read<ChatProvider>().messages;
print('${messages.length} messages in conversation');
```

### Watch for State Changes
```dart
@override
Widget build(BuildContext context) {
  return Consumer<ChatProvider>(
    builder: (context, chatProvider, _) {
      return Column(
        children: [
          // Messages
          ListView.builder(
            itemCount: chatProvider.messages.length,
            itemBuilder: (context, index) {
              final msg = chatProvider.messages[index];
              return Text(msg.content);
            },
          ),
          // Loading indicator
          if (chatProvider.isLoading)
            const CircularProgressIndicator(),
          // Error message
          if (chatProvider.error != null)
            Text('Error: ${chatProvider.error}'),
        ],
      );
    },
  );
}
```

### Send a Message
```dart
// Method 1: Using Provider
context.read<ChatProvider>().sendMessage('Hello AI');

// Method 2: With error handling
try {
  await context.read<ChatProvider>().sendMessage('Hello');
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### Handle Errors
```dart
Consumer<ChatProvider>(
  builder: (context, provider, _) {
    if (provider.error != null) {
      return Column(
        children: [
          Text('❌ ${provider.error}'),
          ElevatedButton(
            onPressed: () => provider.retryLastMessage(),
            child: const Text('Try Again'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  },
)
```

## 5. Common Tasks

### Initialize Chat with Welcome Message
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ChatProvider>().initializeChat(
      welcomeMessage: 'Hello! I am your AI assistant.',
    );
  });
}
```

### Set Conversation Language
```dart
// French
context.read<ChatProvider>().setLanguage('fr');

// Arabic  
context.read<ChatProvider>().setLanguage('ar');

// English (default)
context.read<ChatProvider>().setLanguage('en');
```

### Get Conversation History
```dart
final messages = context.read<ChatProvider>().getConversationHistory();
for (final msg in messages) {
  print('${msg.role}: ${msg.content}');
}
```

### Clear Chat
```dart
context.read<ChatProvider>().clearMessages();
```

### Delete Single Message
```dart
context.read<ChatProvider>().deleteMessage(messageId);
```

## 6. Message Structure

Every message contains:
```dart
class Message {
  final String id;                  // Unique identifier
  final String role;                // 'user' or 'assistant'
  final String content;             // The actual text
  final DateTime timestamp;         // When it was sent
  final bool isLoading;             // Show spinner while loading
}
```

## 7. Webhook Configuration

**Current URL:**
```
https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake
```

**Expected Request:**
```json
POST /webhook/lead-intake
Content-Type: application/json

{
  "message": "user's text here"
}
```

**Expected Response:**
```
Plain text response (not JSON)
Example: "This is the AI response text"
```

## 8. Customization Guide

### Change Webhook URL
**File:** `lib/injection_container.dart`
```dart
late final N8nChatService _n8nChatService = N8nChatService(
  webhookUrl: 'YOUR_NEW_URL_HERE',
);
```

### Modify Chat Colors
**File:** `lib/presentation/pages/chat_page.dart`
```dart
// Line ~82: User message (blue)
color: Colors.blue, // Change this color

// Line ~84: Assistant message (gray)
color: Colors.grey[200], // Change this color
```

### Adjust Request Timeout
**File:** `lib/injection_container.dart`
```dart
late final N8nChatService _n8nChatService = N8nChatService(
  webhookUrl: '...',
  timeout: const Duration(seconds: 60), // Default is 30
);
```

### Add System Instructions
Since n8n handles AI logic, add this in your n8n workflow node to affect behavior across all requests. No code change needed in Flutter.

## 9. Troubleshooting Checklist

- [ ] Did you run `flutter pub get` after updating pubspec.yaml?
- [ ] Is the n8n webhook URL correct?
- [ ] Does the n8n workflow return plain text (not JSON)?
- [ ] Is your internet connection active?
- [ ] Can you curl the webhook directly? 
  ```bash
  curl -X POST https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake \
    -H "Content-Type: application/json" \
    -d '{"message":"test"}'
  ```
- [ ] Are you using `context.read<ChatProvider>()` inside a build method or callback?
- [ ] Is the ChatPage widget wrapped with MultiProvider in app.dart? (Already done ✅)

## 10. Performance Tips

1. **Memory:** Clear old conversations with `chatProvider.clearMessages()`
2. **Network:** Monitor network tab in DevTools for failed requests
3. **UI:** Messages are rendered efficiently with ListView.builder
4. **Timestamps:** Automatically added to each message

## 11. Error Messages Guide

| Error | Cause | Solution |
|-------|-------|----------|
| "Network error: ... socket exception" | No internet | Check WiFi/mobile connection |
| "Connection timeout after 30s" | Webhook too slow | Check n8n workflow, extend timeout |
| "Bad Request: ..." | Invalid message format | Message might contain special chars (handled automatically) |
| "HTTP 401" | Unauthorized | Check webhook URL is correct |
| "HTTP 429" | Rate limited | Wait before sending more messages |
| "HTTP 500, 502, 503" | n8n server issue | Check n8n workflow status |

## 12. Complete Example

```dart
// Complete chat widget example
class SimpleChatWidget extends StatefulWidget {
  const SimpleChatWidget({Key? key}) : super(key: key);

  @override
  State<SimpleChatWidget> createState() => _SimpleChatWidgetState();
}

class _SimpleChatWidgetState extends State<SimpleChatWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initializeChat(
        welcomeMessage: 'Hello! How can I help you?',
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return ListView.builder(
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final msg = provider.messages[index];
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Align(
                      alignment: msg.role == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: msg.role == 'user'
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: msg.isLoading
                            ? const Text('...')
                            : Text(msg.content),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Input area
        Consumer<ChatProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type message...',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !provider.isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            await provider.sendMessage(_controller.text);
                            _controller.clear();
                          },
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
```

## Next Steps

1. ✅ Everything is installed and configured
2. Navigate to `/chat` route from your app
3. Test sending messages
4. Customize styling to match your app theme
5. Add language selection UI if needed
6. Integrate with other screens

---

**Last Updated:** February 9, 2026
