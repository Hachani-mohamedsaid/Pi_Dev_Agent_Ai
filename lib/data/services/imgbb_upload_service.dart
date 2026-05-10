import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/imgbb_config.dart';
import '../../core/network/request_headers.dart';
import '../../core/observability/sentry_api.dart';

/// Upload d'une image vers ImgBB et retourne l'URL publique.
/// POST https://api.imgbb.com/1/upload avec key + image (base64).
class ImgBBUploadService {
  static const _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Envoie [imageBytes] (JPEG/PNG) à ImgBB, retourne l'URL de l'image ou null en cas d'erreur.
  static Future<String?> uploadImage(List<int> imageBytes) async {
    if (imgbbApiKey.isEmpty) return null;
    final base64Image = base64Encode(imageBytes);
    try {
      final res = await http.post(
        Uri.parse(_uploadUrl),
        headers: buildJsonHeaders(),
        body: {'key': imgbbApiKey, 'image': base64Image},
      );
      if (res.statusCode != 200) {
        reportHttpResponseError(feature: 'imgbb.upload', response: res);
        return null;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final d = data?['data'] as Map<String, dynamic>?;
      final url = d?['url'] as String?;
      return url;
    } catch (error, stackTrace) {
      reportApiException(
        feature: 'imgbb.upload',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
