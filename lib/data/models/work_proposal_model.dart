/// Modèle pour les propositions de travail des clients.
class WorkProposal {
  final String id;
  final String clientName;
  final String clientEmail;
  final String projectName;
  final double budget;
  final String period; // ex. "3 mois", "6 semaines"
  final DateTime createdAt;
  final WorkProposalStatus status;
  
  // Détails supplémentaires
  final String typeProjet; // ex. "Application mobile", "Site web", "API"
  final String secteur; // ex. "E-commerce", "Santé", "Finance"
  final String platforme; // ex. "iOS/Android", "Web", "Cross-platform"
  final String fonctionalite; // Description des fonctionnalités
  final double budgetEstime; // Budget estimé (peut être différent de budget)
  final String deadlineEstime; // ex. "3 mois", "6 semaines"
  final String niveauComplexite; // ex. "Simple", "Moyen", "Complexe"

  WorkProposal({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.projectName,
    required this.budget,
    required this.period,
    required this.createdAt,
    this.status = WorkProposalStatus.pending,
    required this.typeProjet,
    required this.secteur,
    required this.platforme,
    required this.fonctionalite,
    required this.budgetEstime,
    required this.deadlineEstime,
    required this.niveauComplexite,
  });

  WorkProposal copyWith({
    String? id,
    String? clientName,
    String? clientEmail,
    String? projectName,
    double? budget,
    String? period,
    DateTime? createdAt,
    WorkProposalStatus? status,
    String? typeProjet,
    String? secteur,
    String? platforme,
    String? fonctionalite,
    double? budgetEstime,
    String? deadlineEstime,
    String? niveauComplexite,
  }) {
    return WorkProposal(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      projectName: projectName ?? this.projectName,
      budget: budget ?? this.budget,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      typeProjet: typeProjet ?? this.typeProjet,
      secteur: secteur ?? this.secteur,
      platforme: platforme ?? this.platforme,
      fonctionalite: fonctionalite ?? this.fonctionalite,
      budgetEstime: budgetEstime ?? this.budgetEstime,
      deadlineEstime: deadlineEstime ?? this.deadlineEstime,
      niveauComplexite: niveauComplexite ?? this.niveauComplexite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'projectName': projectName,
      'budget': budget,
      'period': period,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'typeProjet': typeProjet,
      'secteur': secteur,
      'platforme': platforme,
      'fonctionalite': fonctionalite,
      'budgetEstime': budgetEstime,
      'deadlineEstime': deadlineEstime,
      'niveauComplexite': niveauComplexite,
    };
  }

  factory WorkProposal.fromJson(Map<String, dynamic> json) {
    return WorkProposal(
      id: json['id'] as String,
      clientName: json['clientName'] as String,
      clientEmail: json['clientEmail'] as String,
      projectName: json['projectName'] as String,
      budget: (json['budget'] as num).toDouble(),
      period: json['period'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: WorkProposalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WorkProposalStatus.pending,
      ),
      typeProjet: json['typeProjet'] as String? ?? '',
      secteur: json['secteur'] as String? ?? '',
      platforme: json['platforme'] as String? ?? '',
      fonctionalite: json['fonctionalite'] as String? ?? '',
      budgetEstime: (json['budgetEstime'] as num?)?.toDouble() ?? 0.0,
      deadlineEstime: json['deadlineEstime'] as String? ?? '',
      niveauComplexite: json['niveauComplexite'] as String? ?? '',
    );
  }
}

enum WorkProposalStatus {
  pending,
  accepted,
  rejected,
}
