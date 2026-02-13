# N8N Chat Integration Guide

## Overview

This guide explains how to use the n8n webhook integration for your Flutter chat application. The implementation provides a complete ChatGPT-like experience with message history, loading states, and error handling.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Chat UI (chat_page.dart)                 │
│  • Message list display                                      │
│  • Input field with send button                              │
│  • Loading indicators                                        │
│  • Error handling UI                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│              ChatProvider (chat_provider.dart)               │
│  State Management using Provider package                     │
│  • Manages conversation history                              │
│  • Handles loading state                                     │
│  • Manages error state                                       │
│  • Language selection                                        │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│           N8nChatService (n8n_chat_service.dart)             │
│  HTTP Client for n8n webhook                                │
│  • POST requests to webhook                                  │
│  • Response parsing                                          │
│  • Error handling (timeout, network, server)                │
│  • JSON escaping/unescaping                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│          n8n Webhook (your n8n workflow)                     │
│  https://hachanimohamedsaid.app.n8n.cloud/...               │
│  • Receives: POST {"message": "user text"}                   │
│  • Returns: Plain text response                              │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
lib/
├── data/
│   ├── models/
│   │   └── message_model.dart          # Message structure
│   └── services/
│       └── n8n_chat_service.dart       # n8n webhook client
├── presentation/
│   ├── pages/
│   │   └── chat_page.dart              # Chat UI screen
│   └── state/
│       └── chat_provider.dart          # State management
├── app/
│   └── app.dart                        # Updated with Provider
├── core/
│   └── routing/app_router.dart         # Router config (updated)
├── injection_container.dart            # DI container (updated)
└── pubspec.yaml                        # Dependencies (updated)
```

## Components Explained

### 1. Message Model (`message_model.dart`)

```dart
class Message {
  final String id;           // Unique message ID
  final String role;         // 'user' or 'assistant'
  final String content;      // Message text
  final DateTime timestamp;  // When sent
  final bool isLoading;      // Show loading indicator
}
```

### 2. N8N Chat Service (`n8n_chat_service.dart`)

Handles direct HTTP communication with the n8n webhook.

**Key Features:**
- Sends POST requests with `{"message": "user text"}`
- Handles plain text responses
- Timeout management (30 seconds default)
- Error handling for:
  - Network errors (no internet)
  - Timeouts
  - Server errors (500, 502, 503)
  - Bad requests (400)
  - Authentication (401)
  - Rate limiting (429)

**Usage:**
```dart
final service = N8nChatService(
  webhookUrl: 'https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake'
);

try {
  final response = await service.sendMessage('Hello');
  print(response); // AI response text
} catch (e) {
  print('Error: $e');
}

// Don't forget to dispose
service.dispose();
```

### 3. Chat Provider (`chat_provider.dart`)

Manages chat state using the Provider package.

**Features:**
- Maintains message history
- Handles loading states
- Error management with retry
- Language support (en, fr, ar)
- Conversation history in API format

**Public Methods:**
```dart
void initializeChat({String? welcomeMessage});
Future<void> sendMessage(String userText);
Future<void> retryLastMessage();
void clearMessages();
void deleteMessage(String messageId);
void clearError();
void setLanguage(String languageCode);
List<Message> getConversationHistory();
List<Map<String, String>> getConversationAsApiFormat();
```

**Usage in UI:**
```dart
// Read state
final messages = context.watch<ChatProvider>().messages;
final isLoading = context.watch<ChatProvider>().isLoading;
final error = context.watch<ChatProvider>().error;

// Modify state
context.read<ChatProvider>().sendMessage('Hello');
```

### 4. Chat UI Page (`chat_page.dart`)

Modern ChatGPT-style interface with:
- Message list with timestamps
- User messages aligned right (blue)
- Assistant messages aligned left (gray)
- Typing indicator while loading
- Error banner with retry option
- Input field with send button
- Clear conversation option

## Integration Steps

### Step 1: Add Provider to Dependencies ✅
Already added to `pubspec.yaml`:
```yaml
dependencies:
  provider: ^6.4.0
  http: ^1.2.0
```

### Step 2: Run pub get
```bash
cd /Users/mohamedsaidhachani/Desktop/Pi_Dev_Agent_Ai
flutter pub get
```

### Step 3: Access the Chat Page

**Via Router (Recommended):**
```dart
context.push('/chat');
```

**Via Navigation:**
```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (context) => const ChatPage(),
));
```

### Step 4: Update Your UI Navigation

Add a button to navigate to chat from your home screen:

```dart
ElevatedButton(
  onPressed: () => context.push('/chat'),
  child: const Text('Chat with AI'),
)
```

## Usage Examples

### Basic Chat Interaction

```dart
// In your chat page or any widget
Consumer<ChatProvider>(
  builder: (context, chatProvider, _) {
    return Column(
      children: [
        // Display messages
        ListView.builder(
          itemCount: chatProvider.messages.length,
          itemBuilder: (context, index) {
            final message = chatProvider.messages[index];
            return Text('${message.role}: ${message.content}');
          },
        ),
        // Send button
        ElevatedButton(
          onPressed: () {
            chatProvider.sendMessage('Hello AI');
          },
          child: const Text('Send'),
        ),
      ],
    );
  },
)
```

### Initialize with Welcome Message

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ChatProvider>().initializeChat(
      welcomeMessage: 'Bonjour! Comment puis-je vous aider?'
    );
  });
}
```

### Set Language

```dart
// Set to French
context.read<ChatProvider>().setLanguage('fr');

// Set to Arabic
context.read<ChatProvider>().setLanguage('ar');

// Set to English (default)
context.read<ChatProvider>().setLanguage('en');
```

### Error Handling

```dart
Consumer<ChatProvider>(
  builder: (context, chatProvider, _) {
    if (chatProvider.error != null) {
      return ElevatedButton(
        onPressed: () => chatProvider.retryLastMessage(),
        child: const Text('Retry'),
      );
    }
    return const SizedBox.shrink();
  },
)
```

## Troubleshooting

### Issue: Messages not appearing

**Solution:** Make sure ChatProvider is properly provided in the widget tree:
```dart
// In app.dart (already done)
MultiProvider(
  providers: [
    ChangeNotifierProvider<ChatProvider>(
      create: (_) => InjectionContainer.instance.buildChatProvider(),
    ),
  ],
  child: MaterialApp.router(...),
)
```

### Issue: Webhook timeout

**Solution:** Verify your n8n workflow is running and webhook is active:
1. Check the webhook URL: `https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake`
2. Test with curl: 
   ```bash
   curl -X POST https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello"}'
   ```

### Issue: Empty response from webhook

**Solution:** Ensure your n8n workflow:
1. Returns plain text (not JSON)
2. Maps the input message properly
3. Passes the response through

### Issue: French characters rendering incorrectly

**Solution:** That's handled by Flutter's UTF-8 support. Ensure your n8n workflow returns UTF-8 encoded text.

## Customization

### Change Webhook URL

Update in `injection_container.dart`:
```dart
late final N8nChatService _n8nChatService = N8nChatService(
  webhookUrl: 'YOUR_NEW_WEBHOOK_URL', // Change this
);
```

### Customize Message Colors

In `chat_page.dart`, modify the container decorations:
```dart
Container(
  decoration: BoxDecoration(
    color: isUser ? Colors.blue : Colors.grey[200], // Customize colors
    borderRadius: BorderRadius.circular(12),
  ),
  ...
)
```

### Modify Timeout

In `injection_container.dart`:
```dart
late final N8nChatService _n8nChatService = N8nChatService(
  webhookUrl: 'https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake',
  timeout: const Duration(seconds: 60), // Change from 30 to 60
);
```

### Add Custom System Prompt

Since n8n handles the AI logic, modify your n8n workflow to include a system prompt based on language:

```dart
// In chat_provider.dart, you could send language info:
Future<void> sendMessage(String userText) async {
  // Optionally modify the request to include language
  final message = '$userText (Language: $_selectedLanguage)';
  final response = await chatService.sendMessage(message);
  // ...
}
```

## Testing

### Unit Test Example

```dart
test('ChatProvider sends message and receives response', () async {
  final mockService = MockN8nChatService();
  when(mockService.sendMessage('Hello'))
      .thenAnswer((_) async => 'Hi there!');
  
  final provider = ChatProvider(chatService: mockService);
  await provider.sendMessage('Hello');
  
  expect(provider.messages.length, 2); // user + assistant
  expect(provider.messages.last.content, 'Hi there!');
});
```

### Integration Test Example

```dart
testWidgets('Chat page displays messages', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  
  // Navigate to chat
  await tester.tap(find.byIcon(Icons.chat));
  await tester.pumpAndSettle();
  
  // Type message
  await tester.enterText(find.byType(TextField), 'Hello');
  
  // Send message
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
  
  // Verify message appears
  expect(find.text('Hello'), findsOneWidget);
});
```

## Performance Considerations

1. **Message History:** Conversations are stored in memory. For long conversations (100+ messages), consider:
   - Clearing old messages: `chatProvider.clearMessages()`
   - Persisting to local storage using `shared_preferences`

2. **Network:** Default timeout is 30 seconds. Adjust based on your n8n workflow complexity.

3. **UI Updates:** Provider package efficiently rebuilds only affected widgets.

## Security Notes

1. **Webhook URL:** This URL is embedded in your app. Consider:
   - Using environment variables during build
   - Implementing rate limiting on n8n side
   - Adding authentication headers if needed

2. **Message Data:** Messages are stored in app memory. They're not encrypted. For sensitive data:
   - Implement local encryption
   - Clear messages on app exit
   - Use `secure_storage` package

3. **Network Requests:** All requests use HTTPS with proper certificate validation.

## Next Steps

1. ✅ Install dependencies: `flutter pub get`
2. ✅ Test the chat page: `context.push('/chat')` from any screen
3. ✅ Customize UI colors and styling
4. ✅ Add language selection UI
5. ✅ Integrate with your existing app screens
6. ✅ Test with your n8n workflow

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the code comments in the source files
3. Test your n8n webhook directly with curl
4. Enable debug logging in the service

---

**Created:** February 9, 2026
**Framework:** Flutter 3.10+
**Dependencies:** provider, http, go_router
