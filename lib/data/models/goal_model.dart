/// Action quotidienne liée à un objectif (Today's Action).
class GoalAction {
  final String id;
  final String label;
  final bool completed;

  GoalAction({
    required this.id,
    required this.label,
    this.completed = false,
  });

  factory GoalAction.fromJson(Map<String, dynamic> json) {
    return GoalAction(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      completed: json['completed'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'completed': completed,
      };

  GoalAction copyWith({String? id, String? label, bool? completed}) {
    return GoalAction(
      id: id ?? this.id,
      label: label ?? this.label,
      completed: completed ?? this.completed,
    );
  }
}

/// Objectif utilisateur (goal) avec progression et actions du jour.
class Goal {
  final String id;
  final String title;
  final String category;
  final int progress;
  final String deadline;
  final List<GoalAction> dailyActions;
  final int streak;

  Goal({
    required this.id,
    required this.title,
    required this.category,
    required this.progress,
    required this.deadline,
    required this.dailyActions,
    this.streak = 0,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    final actions = json['dailyActions'] as List<dynamic>?;
    return Goal(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Personal',
      progress: (json['progress'] is int)
          ? json['progress'] as int
          : int.tryParse(json['progress']?.toString() ?? '0') ?? 0,
      deadline: json['deadline']?.toString() ?? 'Ongoing',
      dailyActions: actions != null
          ? actions
              .map((e) => GoalAction.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      streak: (json['streak'] is int)
          ? json['streak'] as int
          : int.tryParse(json['streak']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'progress': progress,
        'deadline': deadline,
        'dailyActions': dailyActions.map((e) => e.toJson()).toList(),
        'streak': streak,
      };

  Goal copyWith({
    String? id,
    String? title,
    String? category,
    int? progress,
    String? deadline,
    List<GoalAction>? dailyActions,
    int? streak,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      deadline: deadline ?? this.deadline,
      dailyActions: dailyActions ?? this.dailyActions,
      streak: streak ?? this.streak,
    );
  }
}
