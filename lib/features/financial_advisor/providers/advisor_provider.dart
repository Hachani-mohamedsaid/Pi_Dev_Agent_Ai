import 'package:flutter/foundation.dart';

import '../models/advisor_report_model.dart';
import '../services/advisor_service.dart';

enum AdvisorStatus { idle, loading, success, error }

class AdvisorProvider extends ChangeNotifier {
  final AdvisorService _service = AdvisorService();

  AdvisorStatus _status = AdvisorStatus.idle;
  AdvisorReportModel? _result;
  String _errorMessage = '';

  AdvisorStatus get status => _status;
  AdvisorReportModel? get result => _result;
  String get errorMessage => _errorMessage;

  Future<void> analyze(String projectText) async {
    if (projectText.trim().isEmpty) {
      _status = AdvisorStatus.error;
      _errorMessage = 'Please enter your project description.';
      notifyListeners();
      return;
    }

    _status = AdvisorStatus.loading;
    _errorMessage = '';
    _result = null;
    notifyListeners();

    try {
      _result = await _service.analyze(projectText);
      _status = AdvisorStatus.success;
      _errorMessage = '';
    } catch (e) {
      _status = AdvisorStatus.error;
      _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      _result = null;
    }
    notifyListeners();
  }

  void reset() {
    _status = AdvisorStatus.idle;
    _result = null;
    _errorMessage = '';
    notifyListeners();
  }
}
