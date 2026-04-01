import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../models/challenge_model.dart';
import '../datasources/auth_local_data_source.dart';

class ChallengesService {
  final String _baseUrl;
  final AuthLocalDataSource _authLocalDataSource;

  ChallengesService({
    String? baseUrl,
    required AuthLocalDataSource authLocalDataSource,
  }) : _baseUrl = baseUrl ?? apiRootUrl,
       _authLocalDataSource = authLocalDataSource;

  static const _headers = {'Content-Type': 'application/json'};

  /// Fetch challenge catalog dynamically from backend.
  /// Expected API response: List<Challenge>
  Future<List<Challenge>> fetchChallengesCatalog() async {
    try {
      final token = await _authLocalDataSource.getAccessToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/challenges/catalog'),
        headers: {
          ..._headers,
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final data = decodedData is List ? decodedData : [];
        if (data.isEmpty) return getMockChallenges();

        final backendChallenges = data
            .map((json) => _parseChallenge(json as Map<String, dynamic>))
            .toList();

        // Keep backend as source of truth, then complete missing entries
        // with local defaults so UI remains complete if backend catalog is partial.
        final defaultChallenges = getMockChallenges();
        final byId = {
          for (final challenge in backendChallenges) challenge.id: challenge,
        };

        return defaultChallenges
            .map((challenge) => byId[challenge.id] ?? challenge)
            .toList();
      }

      return getMockChallenges();
    } catch (_) {
      return getMockChallenges();
    }
  }

  /// Fetch all users with their challenge points and completion status
  /// Expected API response: List<UserProfile>
  Future<List<UserProfile>> fetchLeaderboard() async {
    try {
      final token = await _authLocalDataSource.getAccessToken();
      if (token == null || token.isEmpty) {
        // Fallback to mock data if not authenticated
        return _getMockLeaderboard();
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/users/leaderboard'),
        headers: {..._headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final data = decodedData is List ? decodedData : [];
        if (data.isEmpty) return _getMockLeaderboard();

        return data
            .map((json) => _parseUserProfile(json as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      }
      return _getMockLeaderboard();
    } catch (e) {
      // If endpoint doesn't exist, use mock data
      return _getMockLeaderboard();
    }
  }

  /// Parse user profile from API response JSON
  UserProfile _parseUserProfile(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      avatar: json['avatarUrl'] as String?,
      totalPoints: (json['challengePoints'] ?? json['totalPoints'] ?? 0) as int,
      completedChallengeIds: List<String>.from(
        json['completedChallenges'] as List? ?? [],
      ),
      rank: 0, // Will be recalculated based on points
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  Challenge _parseChallenge(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? '').trim();
    final type = ChallengeType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => ChallengeType.ai_interaction,
    );
    final isVoiceChallenge =
        type == ChallengeType.voice_email ||
        (json['requiresVoice'] as bool? ?? false) ||
        (json['icon'] as String? ?? '') == 'mic';

    final rawColor = json['color'];
    final parsedColor = rawColor is int
        ? Color(rawColor)
        : (rawColor is String && rawColor.startsWith('#'))
        ? Color(int.parse(rawColor.replaceFirst('#', '0xFF')))
        : const Color(0xFF06B6D4);

    return Challenge(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled Challenge',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'award',
      points: (json['points'] as num?)?.toInt() ?? 0,
      color: parsedColor,
      type: type,
      isCompleted: false,
      longDescription: json['longDescription'] as String?,
      steps: List<String>.from(json['steps'] as List? ?? const []),
      requiresVoice: json['requiresVoice'] as bool? ?? false,
      // Voice AI challenges are always free.
      requiresPayment: isVoiceChallenge
          ? false
          : (json['requiresPayment'] as bool? ?? false),
    );
  }

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final token = await _authLocalDataSource.getAccessToken();
      if (token == null || token.isEmpty) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {..._headers, 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserProfile(
          id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
          name: data['name'] as String? ?? 'Unknown',
          email: data['email'] as String? ?? '',
          avatar: data['avatarUrl'] as String?,
          totalPoints: (data['challengePoints'] ?? 0) as int,
          completedChallengeIds: List<String>.from(
            data['completedChallenges'] as List? ?? [],
          ),
          rank: 1,
          isPremium: data['isPremium'] as bool? ?? false,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Complete a challenge and add points to user
  Future<bool> completeChallenge(String challengeId, int points) async {
    try {
      final token = await _authLocalDataSource.getAccessToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/users/complete-challenge'),
        headers: {..._headers, 'Authorization': 'Bearer $token'},
        body: jsonEncode({'challengeId': challengeId, 'points': points}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fallback mock data when API is unavailable
  List<UserProfile> _getMockLeaderboard() {
    return [
      UserProfile(
        id: '1',
        name: 'Ahmed Hassan',
        email: 'ahmed@example.com',
        avatar: null,
        totalPoints: 2450,
        completedChallengeIds: ['1', '2', '3', '4', '5'],
        rank: 1,
        isPremium: true,
      ),
      UserProfile(
        id: '2',
        name: 'Fatima Al Mansouri',
        email: 'fatima@example.com',
        avatar: null,
        totalPoints: 2100,
        completedChallengeIds: ['1', '2', '3', '4'],
        rank: 2,
        isPremium: true,
      ),
      UserProfile(
        id: '3',
        name: 'Mohammed Youssef',
        email: 'mohammed@example.com',
        avatar: null,
        totalPoints: 1850,
        completedChallengeIds: ['1', '2', '3'],
        rank: 3,
        isPremium: false,
      ),
      UserProfile(
        id: '4',
        name: 'Layla Ahmed',
        email: 'layla@example.com',
        avatar: null,
        totalPoints: 1620,
        completedChallengeIds: ['1', '2', '3'],
        rank: 4,
        isPremium: false,
      ),
      UserProfile(
        id: '5',
        name: 'Karim Ibrahim',
        email: 'karim@example.com',
        avatar: null,
        totalPoints: 1420,
        completedChallengeIds: ['1', '2', '3'],
        rank: 5,
        isPremium: false,
      ),
      UserProfile(
        id: '6',
        name: 'Noor Al Mazrouei',
        email: 'noor@example.com',
        avatar: null,
        totalPoints: 1280,
        completedChallengeIds: ['1', '2'],
        rank: 6,
        isPremium: false,
      ),
      UserProfile(
        id: '7',
        name: 'Zainab Al Nomani',
        email: 'zainab@example.com',
        avatar: null,
        totalPoints: 1050,
        completedChallengeIds: ['1', '2'],
        rank: 7,
        isPremium: false,
      ),
      UserProfile(
        id: '8',
        name: 'Omar Khalil',
        email: 'omar@example.com',
        avatar: null,
        totalPoints: 890,
        completedChallengeIds: ['1'],
        rank: 8,
        isPremium: false,
      ),
    ];
  }
}
