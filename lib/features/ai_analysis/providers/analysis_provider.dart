import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analysis_model.dart';
import '../services/ai_analysis_service.dart';

enum AnalysisStatus { idle, loading, success, error }

const String _historyKey = 'ai_analysis_history';

/// Provider for AI business analysis: state, API call, and local history.
class AnalysisProvider extends ChangeNotifier {
  final AiAnalysisService _service = AiAnalysisService();

  AnalysisStatus _status = AnalysisStatus.idle;
  AnalysisModel? _result;
  String _errorMessage = '';

  AnalysisStatus get status => _status;
  AnalysisModel? get result => _result;
  String get errorMessage => _errorMessage;

  List<AnalysisModel> _history = [];
  List<AnalysisModel> get history => List.unmodifiable(_history);

  AnalysisProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_historyKey);
      if (raw == null) return;
      _history = raw
          .map((e) {
            try {
              final map = jsonDecode(e) as Map<String, dynamic>;
              return AnalysisModel.fromJson(map);
            } catch (_) {
              return null;
            }
          })
          .whereType<AnalysisModel>()
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Saves the current result to history (call after success).
  Future<void> saveAnalysis() async {
    if (_result == null) return;
    _history.insert(0, _result!);
    await _persistHistory();
  }

  Future<void> _persistHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw =
          _history.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_historyKey, raw);
      notifyListeners();
    } catch (_) {}
  }

  /// Returns saved analyses (newest first).
  Future<List<AnalysisModel>> getAnalyses() async {
    await _loadHistory();
    return history;
  }

  /// Runs analysis and notifies. On success, result is in [result].
  Future<void> analyze(String idea) async {
    if (idea.trim().isEmpty) {
      _status = AnalysisStatus.error;
      _errorMessage = 'Please enter your business idea.';
      notifyListeners();
      return;
    }

    _status = AnalysisStatus.loading;
    _errorMessage = '';
    _result = null;
    notifyListeners();

    try {
      _result = await _service.analyzeIdea(idea);
      _status = AnalysisStatus.success;
      _errorMessage = '';
      await saveAnalysis();
    } catch (e) {
      _status = AnalysisStatus.error;
      _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      _result = null;
    }
    notifyListeners();
  }

  void reset() {
    _status = AnalysisStatus.idle;
    _result = null;
    _errorMessage = '';
    notifyListeners();
  }
}
