import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/network/request_headers.dart';
import '../../../core/observability/sentry_api.dart';
import '../models/campaign_brief_model.dart';
import '../models/campaign_result_model.dart';

class SocialMediaCampaignException implements Exception {
  final String message;
  final String? body;
  SocialMediaCampaignException(this.message, [this.body]);

  @override
  String toString() => body != null ? '$message\n$body' : message;
}

class SocialMediaCampaignService {
  SocialMediaCampaignService._();
  static final SocialMediaCampaignService instance =
      SocialMediaCampaignService._();

  String get _base => apiBaseUrl;

  // ─── POST /social-campaign/generate ────────────────────────────────────────

  /// Sends the brief to the backend, which saves it (status = "generating")
  /// and fires the N8N webhook in the background.
  /// Returns the new campaign id immediately.
  Future<String> generateCampaign(CampaignBriefModel brief) async {
    final res = await http.post(
      Uri.parse('$_base/social-campaign/generate'),
      headers: buildJsonHeaders(),
      body: jsonEncode({
        'productName': brief.productName,
        'description': brief.description,
        'targetAudience': brief.targetAudience,
        // Backend enum expects lowercase; UI stores capitalized
        'toneOfVoice': brief.toneOfVoice.toLowerCase(),
        'platforms': brief.platforms,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      reportHttpResponseError(
        feature: 'social_campaign.generate',
        response: res,
      );
      throw SocialMediaCampaignException(
        'generateCampaign failed: ${res.statusCode}',
        res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final id = data['id'] as String?;
    if (id == null || id.isEmpty) {
      throw SocialMediaCampaignException(
        'generateCampaign: missing id in response',
        res.body,
      );
    }
    return id;
  }

  // ─── GET /social-campaign/:id ───────────────────────────────────────────────

  /// Fetches the current state of a campaign.
  /// Flutter should call this every 3 s until [CampaignResultModel.isCompleted]
  /// or [CampaignResultModel.isFailed].
  Future<CampaignResultModel> getCampaignStatus(String campaignId) async {
    final res = await http.get(
      Uri.parse('$_base/social-campaign/$campaignId'),
      headers: buildJsonHeaders(),
    );
    if (res.statusCode != 200) {
      reportHttpResponseError(feature: 'social_campaign.status', response: res);
      throw SocialMediaCampaignException(
        'getCampaignStatus failed: ${res.statusCode}',
        res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return CampaignResultModel.fromJson(data);
  }

  // ─── POST /social-campaign/:id/send ────────────────────────────────────────

  /// Updates sentTo / sentAt in MongoDB and triggers the N8N email agent.
  Future<CampaignResultModel> sendCampaignReport(
    String campaignId,
    List<String> recipients,
    String notes,
  ) async {
    final res = await http.post(
      Uri.parse('$_base/social-campaign/$campaignId/send'),
      headers: buildJsonHeaders(),
      body: jsonEncode({'recipients': recipients, 'notes': notes}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      reportHttpResponseError(feature: 'social_campaign.send', response: res);
      throw SocialMediaCampaignException(
        'sendCampaignReport failed: ${res.statusCode}',
        res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return CampaignResultModel.fromJson(data);
  }
}
