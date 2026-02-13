import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

/// Envoie les décisions Accepter/Rejeter vers NestJS (MongoDB) et vers le webhook n8n.
class ProjectService {
  static const Duration _timeout = Duration(seconds: 15);

  /// Body minimal pour n8n (action, row_number, name, email, type_projet).
  Map<String, dynamic> _n8nBody({
    required String action,
    required int rowNumber,
    required String name,
    required String email,
    required String typeProjet,
  }) =>
      {
        'action': action,
        'row_number': rowNumber,
        'name': name,
        'email': email,
        'type_projet': typeProjet,
      };

  /// Récupère les décisions stockées en MongoDB (GET).
  /// Retourne une map row_number (string) -> "accept" | "reject" (dernière décision par row_number).
  Future<Map<String, String>> fetchProjectDecisions() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl$projectDecisionsPath'))
          .timeout(_timeout);
      if (response.statusCode != 200) return {};
      final list = jsonDecode(response.body) as List<dynamic>?;
      if (list == null || list.isEmpty) return {};
      final Map<String, String> out = {};
      final sorted = List<Map<String, dynamic>>.from(
        list.map((e) => Map<String, dynamic>.from(e as Map)),
      );
      sorted.sort((a, b) {
        final aAt = a['createdAt']?.toString() ?? '';
        final bAt = b['createdAt']?.toString() ?? '';
        return (bAt.compareTo(aAt));
      });
      for (final e in sorted) {
        final row = e['row_number'];
        final action = e['action']?.toString();
        if (row == null || action == null) continue;
        final id = row.toString();
        if (action != 'accept' && action != 'reject') continue;
        if (out.containsKey(id)) continue;
        out[id] = action;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// Envoie une décision (accept ou reject) :
  /// 1) vers NestJS (stockage MongoDB)
  /// 2) vers le webhook n8n (workflow n8n).
  /// Retourne [true] si NestJS répond 200 (données bien enregistrées en base).
  Future<bool> sendProjectDecision({
    required String action,
    required int rowNumber,
    required String name,
    required String email,
    required String typeProjet,
    double? budgetEstime,
    String? periode,
  }) async {
    final bodyNest = <String, dynamic>{
      ..._n8nBody(
        action: action,
        rowNumber: rowNumber,
        name: name,
        email: email,
        typeProjet: typeProjet,
      ),
    };
    if (budgetEstime != null && budgetEstime > 0) {
      bodyNest['budget_estime'] = budgetEstime;
    }
    if (periode != null && periode.isNotEmpty && periode != 'À définir') {
      bodyNest['periode'] = periode;
    }

    const headers = {'Content-Type': 'application/json'};
    final bodyN8n = _n8nBody(
      action: action,
      rowNumber: rowNumber,
      name: name,
      email: email,
      typeProjet: typeProjet,
    );

    try {
      // 1) NestJS → MongoDB
      final nestFuture = http.post(
        Uri.parse('$apiBaseUrl$projectDecisionsPath'),
        headers: headers,
        body: jsonEncode(bodyNest),
      ).timeout(_timeout);

      // 2) n8n webhook (workflow n8n)
      final n8nFuture = http.post(
        Uri.parse(projectActionN8nWebhookUrl),
        headers: headers,
        body: jsonEncode(bodyN8n),
      ).timeout(_timeout);

      final results = await Future.wait([nestFuture, n8nFuture]);
      final nestOk = results[0].statusCode == 200;
      final n8nOk = results[1].statusCode == 200;
      return nestOk || n8nOk;
    } catch (_) {
      return false;
    }
  }
}
