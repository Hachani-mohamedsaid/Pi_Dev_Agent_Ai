/// Parsed result from the AI Financial Simulation report (text from n8n/backend).
class AdvisorReportModel {
  final String rawReport;
  final String budget;
  final String monthlyCost;
  final String monthlyRevenue;
  final String monthlyProfit;
  final String successProbability;
  final String failureProbability;
  final String riskLevel;
  final String decision;
  final String summary;
  final String advice;

  const AdvisorReportModel({
    required this.rawReport,
    this.budget = '',
    this.monthlyCost = '',
    this.monthlyRevenue = '',
    this.monthlyProfit = '',
    this.successProbability = '',
    this.failureProbability = '',
    this.riskLevel = '',
    this.decision = '',
    this.summary = '',
    this.advice = '',
  });

  /// Parse report string (e.g. "BUDGET: 7000 TND\nMONTHLY COST: ...").
  static AdvisorReportModel fromReportString(String report) {
    final lines = report.split('\n').map((e) => e.trim()).toList();
    String budget = '', monthlyCost = '', monthlyRevenue = '', monthlyProfit = '';
    String successProbability = '', failureProbability = '', riskLevel = '', decision = '';
    String summary = '', advice = '';
    final summaryLines = <String>[];
    final adviceLines = <String>[];
    var inSummary = false;
    var inAdvice = false;

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('budget:')) {
        budget = line.substring(line.indexOf(':') + 1).trim();
        inSummary = false;
        inAdvice = false;
      } else if (lower.startsWith('monthly cost:')) {
        monthlyCost = line.substring(line.indexOf(':') + 1).trim();
        inSummary = false;
        inAdvice = false;
      } else if (lower.startsWith('monthly revenue:')) {
        monthlyRevenue = line.substring(line.indexOf(':') + 1).trim();
        inSummary = false;
        inAdvice = false;
      } else if (lower.startsWith('monthly profit:')) {
        monthlyProfit = line.substring(line.indexOf(':') + 1).trim();
        inSummary = false;
        inAdvice = false;
      } else if (lower.startsWith('success probability:')) {
        successProbability = line.substring(line.indexOf(':') + 1).trim();
        inSummary = false;
        inAdvice = false;
      } else if (lower.startsWith('failure probability:')) {
        failureProbability = line.substring(line.indexOf(':') + 1).trim();
        inSummary = false;
        inAdvice = false;
      } else if (lower.startsWith('risk level:')) {
        riskLevel = line.substring(line.indexOf(':') + 1).trim();
        inSummary = false;
        inAdvice = false;
      } else if (lower.startsWith('decision:')) {
        decision = line.substring(line.indexOf(':') + 1).trim();
        inSummary = false;
        inAdvice = false;
      } else if (lower.startsWith('summary:')) {
        inSummary = true;
        inAdvice = false;
        final rest = line.substring(line.indexOf(':') + 1).trim();
        if (rest.isNotEmpty) summaryLines.add(rest);
      } else if (lower.startsWith('advice:')) {
        inAdvice = true;
        inSummary = false;
        final rest = line.substring(line.indexOf(':') + 1).trim();
        if (rest.isNotEmpty) adviceLines.add(rest);
      } else if (inSummary && line.isNotEmpty) {
        summaryLines.add(line);
      } else if (inAdvice && line.isNotEmpty) {
        adviceLines.add(line);
      }
    }

    return AdvisorReportModel(
      rawReport: report,
      budget: budget,
      monthlyCost: monthlyCost,
      monthlyRevenue: monthlyRevenue,
      monthlyProfit: monthlyProfit,
      successProbability: successProbability,
      failureProbability: failureProbability,
      riskLevel: riskLevel,
      decision: decision,
      summary: summaryLines.join('\n').trim(),
      advice: adviceLines.join('\n').trim(),
    );
  }
}
