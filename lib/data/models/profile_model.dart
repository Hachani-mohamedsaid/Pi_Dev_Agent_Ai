/// Réponse GET /auth/me – profil utilisateur avec données dynamiques (stats, rôle, phone, birthDate, bio, etc.).
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.role,
    this.location,
    this.phone,
    this.birthDate,
    this.bio,
    this.createdAt,
    this.conversationsCount = 0,
    this.daysActive = 0,
    this.hoursSaved = 0,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? role;
  final String? location;
  final String? phone;
  final String? birthDate;
  final String? bio;
  final String? createdAt;
  final int conversationsCount;
  final int daysActive;
  final int hoursSaved;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String?,
      location: json['location'] as String?,
      phone: json['phone'] as String?,
      birthDate: json['birthDate'] as String?,
      bio: json['bio'] as String?,
      createdAt: json['createdAt'] as String?,
      conversationsCount: (json['conversationsCount'] as num?)?.toInt() ?? 0,
      daysActive: (json['daysActive'] as num?)?.toInt() ?? 0,
      hoursSaved: (json['hoursSaved'] as num?)?.toInt() ?? 0,
    );
  }

  /// Exemple : "Joined January 2024"
  String get joinedLabel {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt!);
    if (date == null) return '';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return 'Joined ${months[date.month - 1]} ${date.year}';
  }
}
