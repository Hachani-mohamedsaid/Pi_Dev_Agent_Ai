import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for communicating with n8n webhook.
/// Handles sending messages and receiving AI responses.
class N8nChatService {
  final String webhookUrl;
  final http.Client httpClient;
  final Duration timeout;

  N8nChatService({
    required this.webhookUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : httpClient = httpClient ?? http.Client();

  /// Send a user message to the n8n webhook and get AI response.
  ///
  /// Throws:
  /// - [TimeoutException] if the request exceeds the timeout
  /// - [SocketException] for network errors
  /// - [Exception] for server errors
  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await httpClient
          .post(
            Uri.parse(webhookUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'text/plain, application/json',
            },
            body: jsonEncode({'message': userMessage}),
          )
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Request timeout after ${timeout.inSeconds}s',
              );
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // n8n can return plain text or JSON like {"output": "..."}
        String responseText = response.body.trim();

        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
          if (decoded != null && decoded.containsKey('output')) {
            final output = decoded['output'];
            if (output != null) {
              return (output is String) ? output.trim() : output.toString();
            }
          }
        } catch (_) {
          // Not JSON, use as plain text below
        }

        // If response is wrapped in quotes, remove them
        if (responseText.startsWith('"') && responseText.endsWith('"')) {
          responseText = responseText.substring(1, responseText.length - 1);
          responseText = responseText
              .replaceAll('\\n', '\n')
              .replaceAll('\\t', '\t')
              .replaceAll('\\"', '"')
              .replaceAll('\\\\', '\\');
        }

        return responseText;
      } else if (response.statusCode == 400) {
        throw Exception('Bad Request: ${response.body}');
      } else if (response.statusCode == 401) {
        throw Exception(
          'Unauthorized: Invalid webhook URL or authentication failed',
        );
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests: Rate limit exceeded');
      } else if (response.statusCode == 500 ||
          response.statusCode == 502 ||
          response.statusCode == 503) {
        throw Exception(
          'Server error (${response.statusCode}): The n8n workflow is temporarily unavailable',
        );
      } else {
        throw Exception('Failed to get response: HTTP ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: ${e.message}. Please check your internet connection.',
      );
    } on TimeoutException catch (e) {
      throw Exception('Connection timeout: ${e.message}');
    } catch (e) {
      throw Exception('Error communicating with n8n: $e');
    }
  }

  /// Send an arbitrary action payload to n8n (e.g. send_email)
  Future<String> sendAction(Map<String, dynamic> payload) async {
    try {
      final body = jsonEncode(payload);
      final response = await httpClient
          .post(
            Uri.parse(webhookUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'text/plain, application/json',
            },
            body: body,
          )
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Request timeout after ${timeout.inSeconds}s',
              );
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.body.trim();
      } else {
        throw Exception('Failed to get response: HTTP ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: ${e.message}. Please check your internet connection.',
      );
    } on TimeoutException catch (e) {
      throw Exception('Connection timeout: ${e.message}');
    } catch (e) {
      throw Exception('Error communicating with n8n: $e');
    }
  }

  /// Close the HTTP client (call this in dispose)
  void dispose() {
    httpClient.close();
  }
}
