class CampaignResultModel {
  final String id;
  final String productName;
  final String description;
  final String targetAudience;
  final String toneOfVoice;
  final List<String> platforms;
  final dynamic campaignResult;
  final String status;
  final List<String> sentTo;
  final DateTime? sentAt;
  final DateTime? createdAt;

  const CampaignResultModel({
    required this.id,
    required this.productName,
    required this.description,
    required this.targetAudience,
    required this.toneOfVoice,
    required this.platforms,
    required this.campaignResult,
    required this.status,
    required this.sentTo,
    this.sentAt,
    this.createdAt,
  });

  factory CampaignResultModel.fromJson(Map<String, dynamic> j) {
    return CampaignResultModel(
      id: j['id'] as String? ?? '',
      productName: j['productName'] as String? ?? '',
      description: j['description'] as String? ?? '',
      targetAudience: j['targetAudience'] as String? ?? '',
      toneOfVoice: j['toneOfVoice'] as String? ?? '',
      platforms: (j['platforms'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      campaignResult: j['campaignResult'],
      status: j['status'] as String? ?? 'generating',
      sentTo: (j['sentTo'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      sentAt: _parseDate(j['sentAt']),
      createdAt: _parseDate(j['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  // ─── Content helpers ────────────────────────────────────────────────────────

  String get campaignResultText {
    final raw = campaignResult;
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is Map) {
      final values = raw.values
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (values.isNotEmpty) return values.join('\n\n');
    }
    return raw.toString().trim();
  }

  /// Human-friendly formatting for long plain-text N8N reports.
  /// Keeps original content but improves spacing for readability.
  String get formattedCampaignResultText {
    final text = campaignResultText;
    if (text.isEmpty) return text;

    var out = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    // Ensure known section headings start on a fresh block.
    final heading = RegExp(
      r'^\s*(instagram|twitter/x|twitter|x \(twitter\)|tiktok|facebook|youtube|analytics)\b',
      caseSensitive: false,
      multiLine: true,
    );
    out = out.replaceAllMapped(heading, (m) {
      final h = m.group(0) ?? '';
      return '\n\n$h';
    });

    // Add spacing before common bullets for easier scanning.
    out = out.replaceAllMapped(
      RegExp(r'^([•*-])\s*', multiLine: true),
      (m) => '\n${m.group(1)} ',
    );

    // Collapse excessive blank lines.
    out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return out.trim();
  }

  bool get hasPlatformSections =>
      _extractDelimitedPlatformSections().isNotEmpty ||
      _extractPlatformSections().isNotEmpty;

  String getPlatformSection(String platform) {
    final delimitedSections = _extractDelimitedPlatformSections();
    final key = _normalizePlatform(platform);
    if (delimitedSections.containsKey(key)) {
      return delimitedSections[key] ?? '';
    }

    final sections = _extractPlatformSections();
    return sections[key] ?? '';
  }

  /// Returns content for a given platform.
  /// For plain-text reports: tries keyword section extraction first.
  /// If no section exists, returns full text as fallback.
  String getContentForPlatform(String platform) {
    final key = _normalizePlatform(platform);
    final delimitedSections = _extractDelimitedPlatformSections();
    if (delimitedSections.isNotEmpty) {
      final section = delimitedSections[key] ?? '';
      print(
        '[SocialCampaign][Model] Delimited section length for $platform: ${section.length}',
      );
      if (section.isNotEmpty) return section;
    }

    final section = getPlatformSection(platform);
    print(
      '[SocialCampaign][Model] Keyword section length for $platform: ${section.length}',
    );
    if (section.isNotEmpty) return section;

    final fullText = campaignResultText;
    if (fullText.isNotEmpty) return fullText;

    final raw = _findPlatformData(platform);
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      for (final key in const [
        'content', 'body', 'strategy', 'text', 'description',
        'caption', 'post', 'message',
      ]) {
        final v = raw[key];
        if (v is String && v.isNotEmpty) return v;
      }
      // Fallback: join all top-level string values
      final parts = raw.values
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join('\n\n');
    }
    return raw.toString();
  }

  /// Returns a headline/title for a platform.
  String getHeadlineForPlatform(String platform) {
    final raw = _findPlatformData(platform);
    if (raw is Map) {
      for (final key in const ['headline', 'title', 'subject', 'name']) {
        final v = raw[key];
        if (v is String && v.isNotEmpty) return v;
      }
    }
    return '$platform Strategy';
  }

  /// Returns a stat value (reach, engagement, posts) for a platform.
  String getStatForPlatform(String platform, String stat) {
    final raw = _findPlatformData(platform);
    if (raw is Map) {
      final v = raw[stat];
      if (v != null) return v.toString();
    }
    return '—';
  }

  dynamic _findPlatformData(String platform) {
    if (campaignResult is! Map) return null;
    final map = campaignResult as Map;

    // 1. Direct key match (e.g. campaignResult['Instagram'])
    if (map.containsKey(platform)) {
      return map[platform];
    }
    // 2. Case-insensitive match
    final lp = platform.toLowerCase();
    for (final entry in map.entries) {
      if (entry.key.toString().toLowerCase() == lp) return entry.value;
    }
    // 3. Nested under 'campaigns', 'platforms', 'results'
    for (final wrapper in const ['campaigns', 'platforms', 'results', 'data']) {
      final sub = map[wrapper];
      if (sub is Map) {
        if (sub.containsKey(platform)) return sub[platform];
        for (final entry in sub.entries) {
          if (entry.key.toString().toLowerCase() == lp) return entry.value;
        }
      }
    }
    return null;
  }

  String _normalizePlatform(String value) {
    final key = value.toLowerCase().trim();
    if (key.contains('instagram')) return 'instagram';
    if (key.contains('twitter') || key.contains('x')) return 'twitter';
    if (key.contains('tiktok')) return 'tiktok';
    if (key.contains('facebook')) return 'facebook';
    if (key.contains('youtube')) return 'youtube';
    if (key.contains('analytics')) return 'analytics';
    return key;
  }

  Map<String, String> _extractPlatformSections() {
    final text = campaignResultText;
    if (text.isEmpty) return const {};

    final pattern = RegExp(
      r'^\s*(instagram|twitter/x|twitter|x \(twitter\)|tiktok|facebook|youtube|analytics)\b.*$',
      caseSensitive: false,
      multiLine: true,
    );
    final matches = pattern.allMatches(text).toList();
    if (matches.isEmpty) return const {};

    final sections = <String, String>{};
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final heading = matches[i].group(1) ?? '';
      final key = _normalizePlatform(heading);
      final slice = text.substring(start, end).trim();
      if (slice.isNotEmpty) {
        sections[key] = slice;
      }
    }
    return sections;
  }

  Map<String, String> _extractDelimitedPlatformSections() {
    final text = campaignResultText;
    if (text.isEmpty) return const {};

    final lines = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final headers = <String, String>{
      '===INSTAGRAM===': 'instagram',
      '===TWITTER===': 'twitter',
      '===TIKTOK===': 'tiktok',
      '===FACEBOOK===': 'facebook',
      '===YOUTUBE===': 'youtube',
      '===ANALYTICS===': 'analytics',
    };

    final headerIndices = <int, String>{};
    for (int i = 0; i < lines.length; i++) {
      final normalized = lines[i].trim().toUpperCase();
      final platformKey = headers[normalized];
      if (platformKey != null) {
        headerIndices[i] = platformKey;
      }
    }

    if (headerIndices.isEmpty) return const {};

    final sortedIndices = headerIndices.keys.toList()..sort();
    final sections = <String, String>{};

    for (int i = 0; i < sortedIndices.length; i++) {
      final startHeaderLine = sortedIndices[i];
      final endHeaderLine =
          i + 1 < sortedIndices.length ? sortedIndices[i + 1] : lines.length;

      final contentLines = lines.sublist(startHeaderLine + 1, endHeaderLine);
      final content = contentLines.join('\n').trim();
      final key = headerIndices[startHeaderLine]!;
      sections[key] = content;
    }

    return sections;
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isGenerating => status == 'generating';
}
