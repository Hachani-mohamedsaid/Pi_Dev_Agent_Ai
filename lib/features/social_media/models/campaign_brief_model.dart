class CampaignBriefModel {
  final String productName;
  final String description;
  final String targetAudience;
  final String toneOfVoice;
  final List<String> platforms;

  const CampaignBriefModel({
    required this.productName,
    required this.description,
    required this.targetAudience,
    required this.toneOfVoice,
    required this.platforms,
  });
}
