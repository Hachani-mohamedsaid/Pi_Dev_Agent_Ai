# N8N Chat Setup Verification Guide

Use this checklist to verify that everything is installed correctly.

## ✅ Step 1: Dependencies

### Check pubspec.yaml contains:
```yaml
provider: ^6.1.5+1
http: ^1.2.0
go_router: ^14.2.0
```

**Verify:**
```bash
cat pubspec.yaml | grep -E "(provider|http|go_router)"
```

---

## ✅ Step 2: File Structure

Run this command to verify all files are created:
```bash
ls -la lib/data/models/message_model.dart
ls -la lib/data/services/n8n_chat_service.dart
ls -la lib/presentation/state/chat_provider.dart
ls -la lib/presentation/pages/chat_page.dart
```

**Expected Output:** 4 files exist ✅

---

## ✅ Step 3: Code Verification

### Verify imports in app.dart:
```bash
grep -n "provider" lib/app/app.dart
grep -n "ChatProvider" lib/app/app.dart
```

**Expected:** Should find `import 'package:provider/provider.dart'` and `ChatProvider`

### Verify ChatProvider is provided:
```bash
grep -n "MultiProvider" lib/app/app.dart
grep -n "buildChatProvider" lib/app/app.dart
```

**Expected:** Should find both MultiProvider and buildChatProvider calls

### Verify routing setup:
```bash
grep -n "'/chat'" lib/core/routing/app_router.dart
grep -n "ChatPage" lib/core/routing/app_router.dart
```

**Expected:** Should find `/chat` route and ChatPage import

### Verify injection setup:
```bash
grep -n "N8nChatService" lib/injection_container.dart
grep -n "buildChatProvider" lib/injection_container.dart
```

**Expected:** Should find both N8nChatService and buildChatProvider

---

## ✅ Step 4: Compilation Check

### Run flutter analyze:
```bash
cd /Users/mohamedsaidhachani/Desktop/Pi_Dev_Agent_Ai
flutter analyze --no-fatal-infos 2>&1 | grep -i "n8n_chat_service\|chat_page\|chat_provider"
```

**Expected:** No errors about our new files (warnings about deprecated code are OK)

### Check for critical errors:
```bash
flutter analyze --fatal-errors 2>&1 | grep -i "error"
```

**Expected:** No output (no errors)

---

## ✅ Step 5: Webhook Configuration

### Verify webhook URL in injection_container:
```bash
grep -n "hachanimohamedsaid.app.n8n.cloud" lib/injection_container.dart
```

**Expected Output:**
```
N8nChatService(
  webhookUrl: 'https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake',
)
```

### Test webhook from command line:
```bash
curl -X POST https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'
```

**Expected:** Should get a text response from your n8n workflow

---

## ✅ Step 6: Code Quality

### Check for syntax errors:
```bash
cd /Users/mohamedsaidhachani/Desktop/Pi_Dev_Agent_Ai
flutter analyze lib/data/models/message_model.dart \
                lib/data/services/n8n_chat_service.dart \
                lib/presentation/state/chat_provider.dart \
                lib/presentation/pages/chat_page.dart
```

**Expected:** No errors on these files

### Check imports:
```bash
grep -n "import" lib/presentation/state/chat_provider.dart | head -5
grep -n "import" lib/presentation/pages/chat_page.dart | head -5
```

**Expected:** All imports valid and resolve

---

## ✅ Step 7: Manual Testing

### 1. Start the app:
```bash
flutter run -v
```

**Expected:** App launches without errors

### 2. Navigate to chat (from code):
In any widget with context:
```dart
context.push('/chat');
```

**Expected:** Chat page loads

### 3. Send a test message:
- Type: "Hello"
- Press Send
- Wait for response

**Expected:** 
- [ ] Message appears on the right (user)
- [ ] Loading indicator shows
- [ ] Response appears on the left (assistant)

### 4. Test error handling:
- Turn off WiFi
- Try to send a message
- Should see error message
- Turn WiFi back on
- Click "Retry"

**Expected:**
- [ ] Error message displays
- [ ] Retry button appears
- [ ] Message sends after retry

### 5. Test language:
```dart
context.read<ChatProvider>().setLanguage('fr');
```

**Expected:** Language is set (you can verify in the provider)

---

## 🔍 Debugging Checklist

### If app doesn't compile:

1. **Provider package not found**
   ```bash
   flutter pub get
   flutter pub clean
   flutter pub get
   ```

2. **Import errors**
   - Check that new files are in correct directories
   - Verify no typos in import statements

3. **Route not found**
   ```bash
   grep "/chat" lib/core/routing/app_router.dart
   ```
   - Should find the GoRoute definition

### If chat page doesn't load:

1. **Check routing works**
   ```dart
   context.push('/home');  // Works?
   context.push('/chat');  // Now try this
   ```

2. **Check Provider is registered**
   ```dart
   // In any widget
   final provider = context.read<ChatProvider>();
   // Should not throw error
   ```

3. **Check imports in chat_page.dart**
   ```bash
   head -20 lib/presentation/pages/chat_page.dart
   ```

### If messages don't send:

1. **Check webhook URL**
   ```bash
   grep "https://" lib/injection_container.dart | grep n8n
   ```

2. **Test webhook directly**
   ```bash
   curl -X POST https://hachanimohamedsaid.app.n8n.cloud/webhook/lead-intake \
     -H "Content-Type: application/json" \
     -d '{"message":"test"}'
   ```

3. **Check network in DevTools**
   - Open DevTools: Press `d` in terminal
   - Go to Network tab
   - Send message
   - Look for POST request to webhook

### If responses don't appear:

1. **Check ChatProvider update**
   ```dart
   // Add logging in chat_provider.dart
   print('Response: $response');
   ```

2. **Check message parsing**
   - Ensure n8n returns plain text
   - Not JSON wrapped
   - UTF-8 encoded

3. **Check UI rebuild**
   - Ensure using `Consumer<ChatProvider>` or `watch()`
   - Not just `read()`

---

## 📋 Configuration File Checklist

### Required Files (4)

- [x] `lib/data/models/message_model.dart`
  - [ ] Contains `Message` class
  - [ ] Has `toApiFormat()` method
  - [ ] Has `copyWith()` method

- [x] `lib/data/services/n8n_chat_service.dart`
  - [ ] Contains `N8nChatService` class
  - [ ] Has `sendMessage()` method
  - [ ] Handles errors properly
  - [ ] Has `dispose()` method

- [x] `lib/presentation/state/chat_provider.dart`
  - [ ] Extends `ChangeNotifier`
  - [ ] Has message list
  - [ ] Has loading/error state
  - [ ] Has `sendMessage()` method
  - [ ] Has `initializeChat()` method

- [x] `lib/presentation/pages/chat_page.dart`
  - [ ] Is a `StatefulWidget`
  - [ ] Uses `Consumer<ChatProvider>`
  - [ ] Has message list UI
  - [ ] Has input field and send button
  - [ ] Shows loading indicator

### Updated Files (4)

- [x] `lib/app/app.dart`
  - [ ] Imports `provider` package
  - [ ] Has `MultiProvider`
  - [ ] Registers `ChatProvider`

- [x] `lib/core/routing/app_router.dart`
  - [ ] Imports `chat_page.dart`
  - [ ] Has `/chat` route
  - [ ] Uses `ChatPage()`

- [x] `lib/injection_container.dart`
  - [ ] Imports `n8n_chat_service.dart`
  - [ ] Imports `chat_provider.dart`
  - [ ] Has `_n8nChatService` field
  - [ ] Has `buildChatProvider()` method
  - [ ] Webhook URL is in this file

- [x] `pubspec.yaml`
  - [ ] Has `provider` dependency
  - [ ] Has correct version
  - [ ] `flutter pub get` runs successfully

---

## 🚀 Test Commands

### Quick test of everything:
```bash
# Clean build
flutter clean
flutter pub get
flutter pub get  # Run twice to be sure

# Analyze
flutter analyze --no-fatal-errors

# Build (don't run, just verify it compiles)
flutter build apk --debug --no-shrink 2>&1 | tail -20

# If it says "Built build/app/outputs/apk..." then ✅ SUCCESS!
```

### For iOS:
```bash
flutter build ios --debug --no-codesign 2>&1 | tail -20
```

### Run the app:
```bash
flutter run
```

---

## 💡 Environment Verification

### Check Flutter version:
```bash
flutter --version
# Should be 3.10+ (your project requires ^3.10.0)
```

### Check Dart version:
```bash
dart --version
# Should match Flutter's Dart version
```

### Check dependencies:
```bash
flutter pub deps
# Should list provider, http, go_router, etc.
```

### Check path:
```bash
which flutter
which dart
which adb  # For Android
xcrun --version  # For iOS (macOS)
```

---

## 🔐 Security Checklist

- [ ] Webhook URL uses HTTPS (✅ it does)
- [ ] No API keys in code (✅ we don't have any)
- [ ] Messages are not encrypted (note: add if handling sensitive data)
- [ ] Network requests use proper headers (✅ Content-Type set)
- [ ] Error messages don't expose sensitive info (✅ generic messages)
- [ ] Timeout is set (✅ 30 seconds default)

---

## Final Verification

Run this complete test:

```bash
#!/bin/bash
set -e

cd /Users/mohamedsaidhachani/Desktop/Pi_Dev_Agent_Ai

echo "=== Checking Files ==="
ls -la lib/data/models/message_model.dart
ls -la lib/data/services/n8n_chat_service.dart
ls -la lib/presentation/state/chat_provider.dart
ls -la lib/presentation/pages/chat_page.dart

echo "=== Checking Dependencies ==="
grep "provider:" pubspec.yaml
grep "http:" pubspec.yaml

echo "=== Checking Imports ==="
grep "ChatProvider" lib/app/app.dart
grep "MultiProvider" lib/app/app.dart
grep "/chat" lib/core/routing/app_router.dart

echo "=== Running Analysis ==="
flutter analyze --no-fatal-infos 2>&1 | head -5

echo "=== All Checks Complete ==="
echo "✅ Setup verification passed!"
```

Save as `verify_setup.sh`, then:
```bash
chmod +x verify_setup.sh
./verify_setup.sh
```

---

## ✨ Success Indicators

You'll know everything is working when:

1. ✅ `flutter run` completes without errors
2. ✅ App launches successfully
3. ✅ Can navigate to `/chat` route
4. ✅ Chat page displays
5. ✅ Can type a message
6. ✅ Send button is active
7. ✅ Loading indicator appears when sending
8. ✅ Response appears from webhook
9. ✅ Message timestamps show
10. ✅ Can clear conversation

---

## 📞 If Something Breaks

1. **Check the error message carefully** - it usually tells you what's wrong

2. **Most common issues and fixes:**

   | Problem | Solution |
   |---------|----------|
   | "ChatProvider not found" | Run `flutter pub get` |
   | "Can't find route /chat" | Check app_router.dart has the route |
   | "Webhook timeout" | Check n8n workflow is running |
   | "import of non-existent file" | Check file paths are correct |
   | "Missing MultiProvider" | Verify app.dart has it |

3. **Check the logs in order:**
   - Look at `flutter analyze` output
   - Check app compilation errors
   - Look at runtime errors in `flutter run -v`
   - Check network requests in DevTools (Press `D` then `N`)

4. **Rollback if needed:**
   ```bash
   git status  # See what changed
   git diff    # See exact changes
   git restore <filename>  # Undo a file
   ```

---

**Everything should be ready to go!** 🎉

If you hit any issues, refer back to this guide or the detailed guides in:
- `docs/N8N_CHAT_INTEGRATION.md`
- `docs/N8N_CHAT_QUICK_START.md`
- `N8N_IMPLEMENTATION_COMPLETE.md`
