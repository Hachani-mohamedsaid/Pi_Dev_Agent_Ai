import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart' show apiRootUrl;

class RagUploadService {
  static const _apiKey = 'ava-n8n-secret-2026';
  static const _n8nBase = 'https://n8n-production-1e13.up.railway.app/webhook';

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null || userId.isEmpty) {
      final cachedJson = prefs.getString('auth_cached_user');
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          userId = decoded['id'] as String? ?? decoded['_id'] as String?;
        } catch (_) {}
      }
    }
    return userId;
  }

  Future<Map<String, dynamic>> _getUserTokens(String userId) async {
    final res = await http.get(
      Uri.parse('$apiRootUrl/users/$userId/google-tokens'),
      headers: {'x-api-key': _apiKey},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('Failed to get tokens');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Ensures the AVA Knowledge Base folder exists in Google Drive.
  /// Returns the folderId.
  Future<String> _ensureRagFolder(String accessToken) async {
    // Search for existing folder
    final searchRes = await http.get(
      Uri.parse(
        "https://www.googleapis.com/drive/v3/files"
        "?q=name%3D'AVA%20Knowledge%20Base'%20and%20mimeType%3D'application%2Fvnd.google-apps.folder'%20and%20trashed%3Dfalse"
        "&fields=files(id%2Cname)",
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(const Duration(seconds: 15));

    if (searchRes.statusCode == 200) {
      final body = jsonDecode(searchRes.body) as Map<String, dynamic>;
      final files = body['files'] as List? ?? [];
      if (files.isNotEmpty) {
        return files[0]['id'] as String;
      }
    }

    // Create folder if not found
    final createRes = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': 'AVA Knowledge Base',
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    ).timeout(const Duration(seconds: 15));

    if (createRes.statusCode != 200 && createRes.statusCode != 201) {
      // 403 typically means the Google access token was issued before the
      // app added the drive.file scope. The user must disconnect and
      // reconnect their Google account so the new scope is granted.
      if (createRes.statusCode == 403) {
        throw Exception(
          'Drive permission required. Please disconnect Google in Connected Services and reconnect to grant Drive access.',
        );
      }
      throw Exception('Failed to create Drive folder: ${createRes.statusCode}');
    }
    final created = jsonDecode(createRes.body) as Map<String, dynamic>;
    return created['id'] as String;
  }

  /// Deletes all existing files in the RAG folder (clean replace).
  Future<void> _clearFolder(String folderId, String accessToken) async {
    final listRes = await http.get(
      Uri.parse(
        "https://www.googleapis.com/drive/v3/files"
        "?q='$folderId'%20in%20parents%20and%20trashed%3Dfalse"
        "&fields=files(id%2Cname)",
      ),
      headers: {'Authorization': 'Bearer $accessToken'},
    ).timeout(const Duration(seconds: 15));

    if (listRes.statusCode != 200) return;
    final files = (jsonDecode(listRes.body)['files'] as List? ?? []);

    for (final file in files) {
      await http.delete(
        Uri.parse('https://www.googleapis.com/drive/v3/files/${file['id']}'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));
    }
  }

  /// Uploads PDF to Google Drive using multipart upload.
  Future<String> _uploadToDrive(
    File pdfFile,
    String fileName,
    String folderId,
    String accessToken,
  ) async {
    final fileBytes = await pdfFile.readAsBytes();
    final boundary = 'boundary_ava_upload_${DateTime.now().millisecondsSinceEpoch}';

    final metadata = jsonEncode({'name': fileName, 'parents': [folderId]});

    final body = StringBuffer();
    body.write('--$boundary\r\n');
    body.write('Content-Type: application/json; charset=UTF-8\r\n\r\n');
    body.write('$metadata\r\n');
    body.write('--$boundary\r\n');
    body.write('Content-Type: application/pdf\r\n\r\n');

    final List<int> bodyBytes = [
      ...utf8.encode(body.toString()),
      ...fileBytes,
      ...utf8.encode('\r\n--$boundary--'),
    ];

    final uploadRes = await http.post(
      Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id,name',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'multipart/related; boundary=$boundary',
        'Content-Length': '${bodyBytes.length}',
      },
      body: bodyBytes,
    ).timeout(const Duration(seconds: 60));

    if (uploadRes.statusCode != 200 && uploadRes.statusCode != 201) {
      throw Exception('Upload failed: ${uploadRes.statusCode} ${uploadRes.body}');
    }
    final uploaded = jsonDecode(uploadRes.body) as Map<String, dynamic>;
    return uploaded['id'] as String;
  }

  /// Saves ragFolderId to backend so N8N can read it.
  Future<void> _saveRagFolderToBackend(
    String userId,
    String ragFolderId,
  ) async {
    await http.post(
      Uri.parse('$apiRootUrl/users/$userId/rag-folder-id'),
      headers: {
        'x-api-key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'ragFolderId': ragFolderId}),
    ).timeout(const Duration(seconds: 15));
  }

  /// Triggers N8N to re-embed the folder contents into Qdrant.
  Future<void> _triggerRagRefresh(String userId, String ragFolderId) async {
    await http.post(
      Uri.parse('$_n8nBase/rag-refresh'),
      headers: {
        'x-api-key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'userId': userId, 'ragFolderId': ragFolderId}),
    ).timeout(const Duration(seconds: 10));
    // Fire and forget — N8N will process async
  }

  /// Main method: full upload flow.
  Future<void> uploadPdf(File pdfFile, String fileName) async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('User not logged in');
    }

    // 1. Get user's Google access token
    final tokens = await _getUserTokens(userId);
    final accessToken = tokens['accessToken'] as String? ?? '';
    if (accessToken.isEmpty) {
      throw Exception('Google account not connected');
    }

    // 2. Ensure RAG folder exists
    final ragFolderId = await _ensureRagFolder(accessToken);

    // 3. Delete old files in folder
    await _clearFolder(ragFolderId, accessToken);

    // 4. Upload new PDF
    await _uploadToDrive(pdfFile, fileName, ragFolderId, accessToken);

    // 5. Save folder ID to backend
    await _saveRagFolderToBackend(userId, ragFolderId);

    // 6. Trigger N8N to re-embed
    await _triggerRagRefresh(userId, ragFolderId);
  }
}

