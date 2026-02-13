import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../data/models/message_model.dart';
import '../../data/services/n8n_chat_service.dart';

/// Extracts clean subject/body from user phrase so the email has proper structure
/// (no "Je envoie mail à X objet : ..." in the body).
(String subject, String body) _parseEmailSubjectAndBody(String userText, String to) {
  String rest = userText
      .replaceAll(to, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  // Remove common prefixes (FR/EN) so only real subject remains
  const prefixes = [
    'envoie mail à ', 'envoye mail à ', 'envoie mail a ', 'envoye mail a ',
    'send email to ', 'envoyer mail à ', 'envoyer mail a ',
    'sujet : ', 'objet : ', 'sujet ', 'objet ', 'subject ', 'mail à ', 'mail a ',
  ];
  bool changed = true;
  while (changed) {
    changed = false;
    for (final p in prefixes) {
      if (rest.toLowerCase().startsWith(p)) {
        rest = rest.substring(p.length).trim();
        changed = true;
        break;
      }
    }
  }
  rest = rest.replaceFirst(RegExp(r'^[:\-\s]+'), '').trim();
  if (rest.isEmpty) rest = 'Sans objet';
  return (rest, rest);
}

/// State management for chat conversations using Provider.
/// Manages message history, loading state, and error handling.
class ChatProvider extends ChangeNotifier {
  final N8nChatService chatService;
  Map<String, String>? _pendingEmail;

  /// Expose pending email details (if any) for the UI to show a confirmation bar.
  Map<String, String>? get pendingEmail =>
      _pendingEmail == null ? null : Map.from(_pendingEmail!);
  bool get hasPendingEmail => _pendingEmail != null;

  // State variables
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  String _selectedLanguage = 'en'; // 'en', 'fr', 'ar'

  ChatProvider({required this.chatService});

  // Getters
  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedLanguage => _selectedLanguage;

  /// Initialize chat with a welcome message
  void initializeChat({String? welcomeMessage}) {
    _messages.clear();
    _error = null;

    if (welcomeMessage != null && welcomeMessage.isNotEmpty) {
      final welcomeMsg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: welcomeMessage,
        timestamp: DateTime.now(),
      );
      _messages.add(welcomeMsg);
      notifyListeners();
    }
  }

  /// Set the conversation language (for display and prompts)
  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode; // 'en', 'fr', 'ar'
    notifyListeners();
  }

  /// Send a user message and get AI response
  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    debugPrint('💬 ChatProvider.sendMessage called with: "${userText.substring(0, math.min(50, userText.length))}..."');

    // Clear previous error
    _error = null;

    // Simple intent detection: check if user asked to send an email
    // Use case-insensitive regex to find email addresses
    final emailRegex = RegExp(
      r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
      caseSensitive: false,
    );
    final lower = userText.toLowerCase().trim();
    final wantsToConfirm = RegExp(
      r"\b(oui|confirme|confirmer|envoye|envoie|ok|ab3th|ab3at|ab3t)\b",
    ).hasMatch(lower);
    // Also treat "request: send email to X" or "send email to <pending>" as confirmation
    final mentionsSendToPending = _pendingEmail != null &&
        (lower.contains('request') && lower.contains('send') && lower.contains('email') ||
            RegExp(r'\b(send|envoyer|envoye)\s+.*(email|mail)\b').hasMatch(lower)) &&
        emailRegex.firstMatch(userText)?.group(0)?.toLowerCase() ==
            _pendingEmail!['to']?.toLowerCase();

    debugPrint('📧 ChatProvider - hasPendingEmail: $_pendingEmail != null');
    debugPrint('📧 ChatProvider - wantsToConfirm: $wantsToConfirm');
    debugPrint('📧 ChatProvider - mentionsSendToPending: $mentionsSendToPending');

    // If we have a pending email and user confirms (or repeats send-email to same address), send it
    if (_pendingEmail != null && (wantsToConfirm || mentionsSendToPending)) {
      final payload = _pendingEmail!;
      final to = payload['to'] ?? '';
      debugPrint('✅ ChatProvider - User confirmed pending email to: $to');
      _pendingEmail = null;
      await sendEmail(
        to: to,
        subject: payload['subject'] ?? 'No subject',
        body: payload['body'] ?? '',
      );
      return;
    }

    // Detect a fresh email request (contains 'mail' and an email address)
    final containsMailWord =
        lower.contains('mail') ||
        lower.contains('mails') ||
        lower.contains('email') ||
        lower.contains('e-mail') ||
        lower.contains('ab3th');
    // Try to find email in both original text and lowercase version
    final emailMatch = emailRegex.firstMatch(userText) ?? emailRegex.firstMatch(lower);
    
    debugPrint('📧 ChatProvider email detection:');
    debugPrint('📧   containsMailWord: $containsMailWord');
    debugPrint('📧   emailMatch: ${emailMatch?.group(0)}');
    debugPrint('📧   userText: "$userText"');
    debugPrint('📧   lower: "$lower"');
    debugPrint('📧   emailRegex test: ${emailRegex.hasMatch(userText)}');
    
    if (containsMailWord && emailMatch != null) {
      final to = emailMatch.group(0)!.trim();
      debugPrint('📧 ✅ EMAIL INTENT DETECTED! Creating pending email for: $to');
      final (subject, body) = _parseEmailSubjectAndBody(userText, to);
      debugPrint('📧 Parsed subject: "$subject"');

      // Save pending email and ask for confirmation instead of sending free-text to n8n
      _pendingEmail = {'to': to, 'subject': subject, 'body': body};

      // Add user message (the original request) so it appears in the chat
      final userMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'user',
        content: userText,
        timestamp: DateTime.now(),
      );
      _messages.add(userMessage);

      // Assistant asks for confirmation locally
      debugPrint('📧 Email intent detected - Created pending email for: $to');
      final confirmMsg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content:
            'Je vais envoyer un mail à $to. Veux-tu que je l\'envoie maintenant ?',
        timestamp: DateTime.now(),
      );
      _messages.add(confirmMsg);
      notifyListeners();
      return;
    }

    // Add user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: userText,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);

    // Add loading message
    final loadingMessage = Message(
      id: '${DateTime.now().millisecondsSinceEpoch}_loading',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );
    _messages.add(loadingMessage);
    _isLoading = true;
    notifyListeners();

    try {
      // Send to n8n webhook
      final response = await chatService.sendMessage(userText);

      // Replace loading message with actual response
      final responseMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );

      _messages.removeLast(); // Remove loading message
      _messages.add(responseMessage);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Remove loading message on error
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        _messages.removeLast();
      }
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retry the last failed message
  Future<void> retryLastMessage() async {
    // Find the last user message
    Message? lastUserMessage;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'user') {
        lastUserMessage = _messages[i];
        break;
      }
    }

    if (lastUserMessage == null) return;

    // Remove error assistant message if exists
    if (_messages.isNotEmpty &&
        _messages.last.role == 'assistant' &&
        _messages.last.content.isEmpty) {
      _messages.removeLast();
    }

    // Resend the message
    await sendMessage(lastUserMessage.content);
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Delete a specific message
  void deleteMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get conversation as list of Message objects for context
  List<Message> getConversationHistory() => List.from(_messages);

  /// Get conversation in API format (for potential future use)
  List<Map<String, String>> getConversationAsApiFormat() {
    return _messages
        .where((msg) => !msg.isLoading) // Exclude loading messages
        .map((msg) => msg.toApiFormat())
        .toList();
  }

  /// Trigger sending an email via n8n webhook.
  /// Uses sendMessage() so the n8n AI Agent (with Gmail tool) receives a clear instruction.
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    _error = null;

    // Demander à l'agent de corriger les fautes avant envoi, puis envoyer un mail propre
    final instruction =
        'Envoie un e-mail à $to. '
        'Le sujet souhaité par l\'utilisateur est : « $subject ». '
        'Le contenu souhaité est : « $body ». '
        'Corrige les fautes d\'orthographe et de grammaire (ex. envouye→envoie, lobject→l\'objet, reuion→réunion) dans le sujet et le corps avant d\'envoyer. '
        'L\'objet du mail doit être le sujet corrigé. Le corps du mail doit contenir uniquement le message corrigé, sans phrase du type "je envoie mail à" ni l\'adresse.';
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: instruction,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);

    final loadingMessage = Message(
      id: '${DateTime.now().millisecondsSinceEpoch}_email_loading',
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );
    _messages.add(loadingMessage);
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📧 n8n.sendEmail via sendMessage: $to — $subject');

      final response = await chatService.sendMessage(instruction);

      debugPrint('✅ n8n.sendEmail response: ${response.substring(0, response.length > 80 ? 80 : response.length)}...');

      final successMessage = response.trim().isNotEmpty
          ? response
          : 'Mail envoyé avec succès à $to.';

      if (_messages.isNotEmpty && _messages.last.isLoading) {
        _messages.removeLast();
      }
      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: successMessage,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ n8n.sendEmail error: $e');
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        _messages.removeLast();
      }
      _error = e.toString();
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content:
            'Désolé, une erreur s\'est produite lors de l\'envoi du mail à $to. Veuillez réessayer.',
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Confirm and send the pending email saved by intent detection.
  Future<void> confirmPendingEmail() async {
    final payload = _pendingEmail;
    if (payload == null) {
      debugPrint('⚠️ confirmPendingEmail called but no pending email exists');
      return;
    }
    final to = payload['to'] ?? '';
    final subject = payload['subject'] ?? 'No subject';
    debugPrint('✅ confirmPendingEmail - Sending email to: $to, subject: $subject');
    
    _pendingEmail = null;
    notifyListeners();

    await sendEmail(
      to: to,
      subject: subject,
      body: payload['body'] ?? '',
    );
  }

  /// Cancel the pending email request and inform the user in the conversation.
  void cancelPendingEmail() {
    if (_pendingEmail == null) {
      debugPrint('⚠️ cancelPendingEmail called but no pending email exists');
      return;
    }
    final to = _pendingEmail!['to'] ?? 'destinataire';
    debugPrint('❌ cancelPendingEmail - Cancelling email to: $to');
    
    _pendingEmail = null;

    final cancelMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: 'Action d\'envoi d\'e-mail à $to annulée.',
      timestamp: DateTime.now(),
    );
    _messages.add(cancelMsg);
    notifyListeners();
  }

  @override
  void dispose() {
    chatService.dispose();
    super.dispose();
  }
}
