import 'dart:math';

/// Builds JSON headers for API calls with a per-request correlation id.
Map<String, String> buildJsonHeaders({
  String? bearerToken,
  Map<String, String>? extra,
}) {
  final headers = <String, String>{
    'Content-Type': 'application/json',
    'x-request-id': newRequestId(),
  };

  final normalizedToken = _normalizeToken(bearerToken);
  if (normalizedToken != null) {
    headers['Authorization'] = 'Bearer $normalizedToken';
  }

  if (extra != null && extra.isNotEmpty) {
    headers.addAll(extra);
  }

  return headers;
}

String? _normalizeToken(String? token) {
  if (token == null) return null;
  final trimmed = token.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.toLowerCase().startsWith('bearer ')) {
    final stripped = trimmed.substring(7).trim();
    return stripped.isEmpty ? null : stripped;
  }

  return trimmed;
}

/// Lightweight UUID v4-like id (enough for request correlation across systems).
String newRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  // Set RFC4122-like version/variant bits for readability in logs.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}
