import 'package:flutter/foundation.dart';

/// Modèle pour les propositions de l'API REST
class Proposal {
  final int rowNumber;
  final String name;
  final String email;
  final String typeProjet;
  final String secteur;
  final String plateformes;
  final String fonctionnalites;
  final double budgetEstime;
  final String deadlineEstime; // Délai estimé (deadline)

  Proposal({
    required this.rowNumber,
    required this.name,
    required this.email,
    required this.typeProjet,
    required this.secteur,
    required this.plateformes,
    required this.fonctionnalites,
    required this.budgetEstime,
    this.deadlineEstime = '',
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    // Gérer budget_estime qui peut être un nombre ou une chaîne
    double budgetEstime = 0.0;
    final budgetValue = json['budget_estime'];
    if (budgetValue != null) {
      if (budgetValue is num) {
        budgetEstime = budgetValue.toDouble();
      } else if (budgetValue is String) {
        // Extraire le premier nombre trouvé dans la chaîne
        final regex = RegExp(r'(\d+(?:[.,]\d+)?)');
        final match = regex.firstMatch(budgetValue);
        if (match != null) {
          budgetEstime = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0.0;
        }
      }
    }

    // Gérer deadline_estime - vérifier plusieurs variantes possibles
    String deadlineEstime = '';
    if (json.containsKey('deadline_estime')) {
      deadlineEstime = json['deadline_estime']?.toString() ?? '';
    } else if (json.containsKey('deadline')) {
      deadlineEstime = json['deadline']?.toString() ?? '';
    } else if (json.containsKey('period')) {
      deadlineEstime = json['period']?.toString() ?? '';
    } else if (json.containsKey('periode')) {
      deadlineEstime = json['periode']?.toString() ?? '';
    }
    
    // Debug pour voir ce qui est disponible
    if (kDebugMode && deadlineEstime.isEmpty) {
      debugPrint('⚠️ deadline_estime non trouvé. Clés disponibles: ${json.keys}');
    }

    return Proposal(
      rowNumber: json['row_number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      typeProjet: json['type_projet'] as String? ?? '',
      secteur: json['secteur'] as String? ?? '',
      plateformes: json['plateformes'] as String? ?? '',
      fonctionnalites: json['fonctionnalites'] as String? ?? '',
      budgetEstime: budgetEstime,
      deadlineEstime: deadlineEstime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row_number': rowNumber,
      'name': name,
      'email': email,
      'type_projet': typeProjet,
      'secteur': secteur,
      'plateformes': plateformes,
      'fonctionnalites': fonctionnalites,
      'budget_estime': budgetEstime,
      'deadline_estime': deadlineEstime,
    };
  }
}
