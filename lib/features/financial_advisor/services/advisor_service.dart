import '../data/advisor_remote_data_source.dart';
import '../models/advisor_report_model.dart';

/// Repository/service: call API then parse report.
class AdvisorService {
  final AdvisorRemoteDataSource _dataSource = AdvisorRemoteDataSource();

  /// Sends project text to backend; returns parsed report. On backend failure, tries n8n webhook.
  Future<AdvisorReportModel> analyze(String projectText) async {
    String report;
    try {
      report = await _dataSource.sendToBackend(projectText);
    } catch (_) {
      report = await _dataSource.sendToWebhook(projectText);
    }
    return AdvisorReportModel.fromReportString(report);
  }
}
