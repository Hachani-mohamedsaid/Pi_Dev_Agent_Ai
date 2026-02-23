/// One month in the project financial breakdown (income, cost, profit).
class MonthEntry {
  final int month;
  final String monthLabel;
  final double income;
  final double cost;
  final double profit;
  final String notes;

  const MonthEntry({
    required this.month,
    required this.monthLabel,
    required this.income,
    required this.cost,
    required this.profit,
    this.notes = '',
  });

  factory MonthEntry.fromJson(Map<String, dynamic> json) {
    return MonthEntry(
      month: _toInt(json['month']),
      monthLabel: json['month_label'] as String? ?? json['monthLabel'] as String? ?? '',
      income: _toDouble(json['income']),
      cost: _toDouble(json['cost']),
      profit: _toDouble(json['profit']),
      notes: json['notes'] as String? ?? '',
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
