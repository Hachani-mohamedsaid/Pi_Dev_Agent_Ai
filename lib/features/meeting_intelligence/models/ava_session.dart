/// Passed through briefing flow so tabs use the same context as Meeting Setup.
class AvaSession {
  const AvaSession({
    required this.sessionId,
    this.investorName,
    this.investorCompany,
    this.country,
    this.city,
    this.userEquity,
    this.userValuation,
    this.meetingFormat,
  });

  final String sessionId;
  final String? investorName;
  final String? investorCompany;
  final String? country;
  final String? city;
  final String? userEquity;
  final String? userValuation;
  final String? meetingFormat;
}
