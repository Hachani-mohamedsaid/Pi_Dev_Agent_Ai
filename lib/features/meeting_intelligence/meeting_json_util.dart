// Helpers so briefing DTOs accept both snake_case and camelCase from the API.

String pickString(
  Map<String, dynamic> j,
  List<String> keys, [
  String fallback = '',
]) {
  for (final k in keys) {
    final v = j[k];
    if (v != null && v.toString().isNotEmpty) return v.toString();
  }
  return fallback;
}

List<String> pickStringList(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
  }
  return [];
}

int pickInt(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is int) return v;
    if (v is num) return v.round();
    final p = int.tryParse(v.toString());
    if (p != null) return p;
  }
  return 0;
}

bool pickBool(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v == true || v == 1) return true;
    if (v == false || v == 0) return false;
    if (v is String) {
      final l = v.toLowerCase();
      if (l == 'true' || l == '1') return true;
      if (l == 'false' || l == '0') return false;
    }
  }
  return false;
}

double pickDouble(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is num) return v.toDouble();
    final p = double.tryParse(v.toString());
    if (p != null) return p;
  }
  return 0;
}

/// Like [pickString] but returns null if the key is absent or value is null/empty.
String? pickNullableString(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    if (!j.containsKey(k)) continue;
    final v = j[k];
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }
  return null;
}
