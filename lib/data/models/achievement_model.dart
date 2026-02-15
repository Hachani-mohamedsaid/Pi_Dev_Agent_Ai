/// Récompense / achievement récent (streak, tâches complétées, objectif atteint).
class Achievement {
  final String id;
  final String icon;
  final String title;
  final String date;

  Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.date,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '🏆',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'icon': icon,
        'title': title,
        'date': date,
      };
}
