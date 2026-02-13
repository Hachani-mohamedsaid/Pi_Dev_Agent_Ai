import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/work_proposal_model.dart';

/// Service pour analyser un projet avec OpenAI et sauvegarder dans MongoDB.
class OpenAIAnalysisService {
  static const Duration _timeout = Duration(seconds: 30);
  static const String _openaiApiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Récupère l'analyse depuis MongoDB si elle existe.
  Future<ProjectAnalysis?> getAnalysisFromMongo(int rowNumber) async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl$projectAnalysesPath/$rowNumber'))
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (json == null || json['analysis'] == null) return null;
      return _parseAnalysisFromJson(json['analysis'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Sauvegarde l'analyse dans MongoDB.
  Future<bool> saveAnalysisToMongo(int rowNumber, ProjectAnalysis analysis) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl$projectAnalysesPath'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'row_number': rowNumber,
          'analysis': _analysisToJson(analysis),
        }),
      ).timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Analyse un projet avec OpenAI, sauvegarde dans MongoDB et retourne l'analyse.
  /// Si l'analyse existe déjà en base, la retourne sans appeler OpenAI.
  Future<ProjectAnalysis?> analyzeProject(WorkProposal proposal) async {
    final rowNumber = int.tryParse(proposal.id) ?? 0;
    if (rowNumber == 0) return null;

    // 1) Vérifier si l'analyse existe déjà en MongoDB
    final existingAnalysis = await getAnalysisFromMongo(rowNumber);
    if (existingAnalysis != null) {
      return existingAnalysis;
    }

    // 2) Générer avec OpenAI
    try {
      final prompt = _buildAnalysisPrompt(proposal);
      
      final response = await http.post(
        Uri.parse(_openaiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openaiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'Tu es un expert en développement de projets web/mobile. '
                  'Analyse les projets de manière professionnelle et détaillée. '
                  'Réponds toujours en français, de manière structurée et claire.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 3000,
        }),
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final content = json['choices']?[0]?['message']?['content'] as String?;
      if (content == null) return null;

      final analysis = _parseAnalysis(content, proposal);
      
      // 3) Sauvegarder dans MongoDB
      await saveAnalysisToMongo(rowNumber, analysis);
      
      return analysis;
    } catch (_) {
      return null;
    }
  }

  ProjectAnalysis _parseAnalysisFromJson(Map<String, dynamic> json) {
    return ProjectAnalysis(
      tools: List<String>.from(json['tools'] ?? []),
      technicalProposal: TechnicalProposal(
        architecture: json['technicalProposal']?['architecture'] ?? '',
        stack: json['technicalProposal']?['stack'] ?? '',
        security: json['technicalProposal']?['security'] ?? '',
        performance: json['technicalProposal']?['performance'] ?? '',
        tests: json['technicalProposal']?['tests'] ?? '',
        deployment: json['technicalProposal']?['deployment'] ?? '',
        monitoring: json['technicalProposal']?['monitoring'] ?? '',
      ),
      howToWork: json['howToWork'] ?? '',
      developmentSteps: (json['developmentSteps'] as List<dynamic>?)
              ?.map((e) => DevelopmentStep(
                    title: e['title'] ?? '',
                    description: e['description'] ?? '',
                  ))
              .toList() ??
          [],
      recommendations: json['recommendations'] ?? '',
    );
  }

  Map<String, dynamic> _analysisToJson(ProjectAnalysis analysis) {
    return {
      'tools': analysis.tools,
      'technicalProposal': {
        'architecture': analysis.technicalProposal.architecture,
        'stack': analysis.technicalProposal.stack,
        'security': analysis.technicalProposal.security,
        'performance': analysis.technicalProposal.performance,
        'tests': analysis.technicalProposal.tests,
        'deployment': analysis.technicalProposal.deployment,
        'monitoring': analysis.technicalProposal.monitoring,
      },
      'howToWork': analysis.howToWork,
      'developmentSteps': analysis.developmentSteps
          .map((e) => {'title': e.title, 'description': e.description})
          .toList(),
      'recommendations': analysis.recommendations,
    };
  }

  String _buildAnalysisPrompt(WorkProposal proposal) {
    return '''
Analyse ce projet de développement en détail et fournis une analyse complète structurée.

**Informations du projet:**
- Type de projet: ${proposal.typeProjet}
- Secteur: ${proposal.secteur}
- Plateforme: ${proposal.platforme}
- Budget estimé: ${proposal.budgetEstime}€
- Délai estimé: ${proposal.deadlineEstime}
- Fonctionnalités: ${proposal.fonctionalite}
- Niveau de complexité: ${proposal.niveauComplexite}

**Demande d'analyse:**
Fournis une analyse complète en JSON avec cette structure exacte:
{
  "tools": ["outil1", "outil2", ...],
  "technicalProposal": {
    "architecture": "description architecture",
    "stack": "description stack technique",
    "security": "description sécurité",
    "performance": "description performance",
    "tests": "description tests",
    "deployment": "description déploiement",
    "monitoring": "description monitoring"
  },
  "howToWork": "description détaillée comment travailler ce projet",
  "developmentSteps": [
    {"title": "Étape 1", "description": "description"},
    {"title": "Étape 2", "description": "description"},
    ...
  ],
  "recommendations": "recommandations générales"
}

IMPORTANT: Réponds UNIQUEMENT avec le JSON valide, sans texte avant ou après.
''';
  }

  ProjectAnalysis _parseAnalysis(String content, WorkProposal proposal) {
    try {
      // Extraire le JSON du contenu (peut contenir du markdown)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        return _createDefaultAnalysis(proposal);
      }
      final jsonStr = jsonMatch.group(0)!;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      return ProjectAnalysis(
        tools: List<String>.from(json['tools'] ?? []),
        technicalProposal: TechnicalProposal(
          architecture: json['technicalProposal']?['architecture'] ?? '',
          stack: json['technicalProposal']?['stack'] ?? '',
          security: json['technicalProposal']?['security'] ?? '',
          performance: json['technicalProposal']?['performance'] ?? '',
          tests: json['technicalProposal']?['tests'] ?? '',
          deployment: json['technicalProposal']?['deployment'] ?? '',
          monitoring: json['technicalProposal']?['monitoring'] ?? '',
        ),
        howToWork: json['howToWork'] ?? '',
        developmentSteps: (json['developmentSteps'] as List<dynamic>?)
                ?.map((e) => DevelopmentStep(
                      title: e['title'] ?? '',
                      description: e['description'] ?? '',
                    ))
                .toList() ??
            [],
        recommendations: json['recommendations'] ?? '',
      );
    } catch (_) {
      return _createDefaultAnalysis(proposal);
    }
  }

  ProjectAnalysis _createDefaultAnalysis(WorkProposal proposal) {
    return ProjectAnalysis(
      tools: [],
      technicalProposal: TechnicalProposal(
        architecture: 'Architecture à définir',
        stack: 'Stack à définir',
        security: 'Sécurité à définir',
        performance: 'Performance à définir',
        tests: 'Tests à définir',
        deployment: 'Déploiement à définir',
        monitoring: 'Monitoring à définir',
      ),
      howToWork: 'Méthodologie à définir',
      developmentSteps: [],
      recommendations: 'Recommandations à définir',
    );
  }
}

/// Modèle pour l'analyse OpenAI d'un projet.
class ProjectAnalysis {
  final List<String> tools;
  final TechnicalProposal technicalProposal;
  final String howToWork;
  final List<DevelopmentStep> developmentSteps;
  final String recommendations;

  ProjectAnalysis({
    required this.tools,
    required this.technicalProposal,
    required this.howToWork,
    required this.developmentSteps,
    required this.recommendations,
  });
}

class TechnicalProposal {
  final String architecture;
  final String stack;
  final String security;
  final String performance;
  final String tests;
  final String deployment;
  final String monitoring;

  TechnicalProposal({
    required this.architecture,
    required this.stack,
    required this.security,
    required this.performance,
    required this.tests,
    required this.deployment,
    required this.monitoring,
  });
}

class DevelopmentStep {
  final String title;
  final String description;

  DevelopmentStep({
    required this.title,
    required this.description,
  });
}
