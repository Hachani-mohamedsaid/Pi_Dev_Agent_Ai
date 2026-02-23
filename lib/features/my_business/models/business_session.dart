/// Session data for My Business flow: URL + chosen dashboard style.
class BusinessSession {
  const BusinessSession({
    required this.websiteUrl,
    this.styleIndex = 0,
  });

  final String websiteUrl;
  final int styleIndex;

  BusinessSession copyWith({String? websiteUrl, int? styleIndex}) {
    return BusinessSession(
      websiteUrl: websiteUrl ?? this.websiteUrl,
      styleIndex: styleIndex ?? this.styleIndex,
    );
  }
}
