# N8N Chat Integration - Quick Reference Card

## 📱 How to Use in Your App

### 1. **Navigate to Chat**
```dart
// From any widget
context.push('/chat');
```

### 2. **Send a Message Programmatically**
```dart
context.read<ChatProvider>().sendMessage('Hello AI');
```

### 3. **Watch Message Updates**
```dart
Consumer<ChatProvider>(
  builder: (context, chatProvider, _) {
    return ListView.builder(
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final msg = chatProvider.messages[index];
        return Text('${msg.role}: ${msg.content}');
      },
    );
  },
)
```

### 4. **Handle Loading State**
```dart
if (context.watch<ChatProvider>().isLoading) {
  return const CircularProgressIndicator();
}
```

### 5. **Handle Errors**
```dart
final error = context.watch<ChatProvider>().error;
if (error != null) {
  // Show error UI
  Text('Error: $error')
}
```

---

## 📁 File Locations

| What | Where |
|------|-------|
| Message model | `lib/data/models/message_model.dart` |
| HTTP service | `lib/data/services/n8n_chat_service.dart` |
| State management | `lib/presentation/state/chat_provider.dart` |
| Chat UI | `lib/presentation/pages/chat_page.dart` |
| App config | `lib/app/app.dart` (MultiProvider) |
| Routing | `lib/core/routing/app_router.dart` (added /chat) |
| DI container | `lib/injection_container.dart` |
| Dependencies | `pubspec.yaml` (provider added) |

---

## 🔧 Configuration

### Change Webhook URL
**File:** `lib/injection_container.dart` (line ~119)
```dart
late final N8nChatService _n8nChatService = N8nChatService(
  webhookUrl: 'https://your-new-url.com/webhook',
);
```

### Change Colors
**File:** `lib/presentation/pages/chat_page.dart`
```dart
color: Colors.blue,        // User message (line ~82)
color: Colors.grey[200],   // Assistant message (line ~84)
```

### Change Timeout
**File:** `lib/injection_container.dart` (line ~119)
```dart
late final N8nChatService _n8nChatService = N8nChatService(
  webhookUrl: '...',
  timeout: const Duration(seconds: 60), // Change from 30
);
```

---

## 🚀 Webhook Details

**Current URL:**
```
https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake
```

**Request Format:**
```json
POST /webhook/lead-intake
Content-Type: application/json

{
  "message": "user message text"
}
```

**Response Format:**
```
Plain text response (NOT JSON)
Example: "This is the AI response"
```

**Test It:**
```bash
curl -X POST https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello"}'
```

---

## 📊 Architecture at a Glance

```
ChatPage (UI)
    ↓ uses
ChatProvider (State)
    ↓ uses
N8nChatService (HTTP)
    ↓ sends to
N8N Webhook (AI)
```

---

## ✨ Key Methods

### ChatProvider Methods
```dart
// Send message to n8n
await chatProvider.sendMessage('Hello');

// Initialize with welcome message
chatProvider.initializeChat(welcomeMessage: 'Welcome!');

// Set language (en, fr, ar)
chatProvider.setLanguage('fr');

// Get all messages
final messages = chatProvider.getConversationHistory();

// Clear all messages
chatProvider.clearMessages();

// Delete specific message
chatProvider.deleteMessage(messageId);

// Retry last message
chatProvider.retryLastMessage();

// Clear error
chatProvider.clearError();
```

---

## 🎯 Step-by-Step Setup

### Step 1: Dependencies Already Added ✅
```bash
flutter pub get
```

### Step 2: Wrap App with Provider ✅
Done in `lib/app/app.dart`

### Step 3: Add Route ✅
Done in `lib/core/routing/app_router.dart`

### Step 4: Register Service ✅
Done in `lib/injection_container.dart`

### Step 5: Use in Your App
```dart
// Add button to home screen
ElevatedButton(
  onPressed: () => context.push('/chat'),
  child: const Text('Chat'),
)
```

---

## 🧪 Test the Integration

### 1. Run the app
```bash
flutter run
```

### 2. Navigate to chat
Click your chat button or use:
```dart
context.push('/chat');
```

### 3. Send a message
Type "Hello" and press send

### 4. Verify response
Should see AI response from your n8n workflow

---

## 🚨 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| "ChatProvider not found" | Run `flutter pub get` |
| "Route /chat not found" | Verify app_router.dart has route |
| "Webhook timeout" | Check n8n workflow is running |
| "No response" | Test webhook with curl command above |
| "Messages not showing" | Ensure using `Consumer<ChatProvider>` or `watch()` |

---

## 📚 Documentation Files

- **Complete Guide:** `docs/N8N_CHAT_INTEGRATION.md`
- **Quick Start:** `docs/N8N_CHAT_QUICK_START.md`
- **Implementation Summary:** `N8N_IMPLEMENTATION_COMPLETE.md`
- **Verification Guide:** `VERIFICATION_GUIDE.md`

---

## ✅ Verification Checklist

Run these commands to verify setup:

```bash
# Check files exist
ls lib/data/models/message_model.dart
ls lib/data/services/n8n_chat_service.dart
ls lib/presentation/state/chat_provider.dart
ls lib/presentation/pages/chat_page.dart

# Check dependencies
grep "provider:" pubspec.yaml

# Check imports
grep "ChatProvider" lib/app/app.dart
grep "/chat" lib/core/routing/app_router.dart

# Compile check
flutter analyze --no-fatal-infos 2>&1 | grep "No issues" || echo "Has issues"

# Run app
flutter run
```

---

## 💡 Pro Tips

1. **Reuse ChatProvider** - It's a singleton, so message history persists across navigation
2. **Language Support** - Built-in support for en, fr, ar
3. **Retry Feature** - Error messages include automatic retry
4. **Clean Code** - Follows Flutter best practices and Clean Architecture
5. **Responsive** - Works on all screen sizes

---

## 🎬 Quick Example

Complete working example:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ... other imports

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // App is already wrapped with Provider in app.dart
    return const App(); // Use your existing App widget
  }
}

// In any page:
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.push('/chat'),
          child: const Text('Open Chat'),
        ),
      ),
    );
  }
}

// Chat page is auto-generated and ready to use!
// Just navigate with context.push('/chat');
```

---

## 📞 Need Help?

1. **Check the error message** - Usually tells you exactly what's wrong
2. **Verify webhook works** - Test with curl
3. **Check logs** - Run with `flutter run -v`
4. **Read the full guides** - They have troubleshooting sections
5. **Test locally first** - Don't deploy until you verify locally

---

## 🎉 You're All Set!

Your Flutter app is now connected to your n8n AI Agent!

- ✅ Chat UI ready
- ✅ Message handling done
- ✅ Error handling included
- ✅ Language support built-in
- ✅ State management configured
- ✅ Routing set up

Just navigate to `/chat` and start chatting!

---

**Last Updated:** February 9, 2026 | **Status:** Production Ready ✨
