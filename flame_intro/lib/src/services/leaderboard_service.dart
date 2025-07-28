import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// Import dart:js for web-specific JavaScript interop
import 'dart:js' as js;

class Player {
  final int id;
  final String name;
  final DateTime createdAt;

  Player({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class ScoreSubmission {
  final int id;
  final int playerId;
  final int score;
  final DateTime createdAt;
  final int? rank;

  ScoreSubmission({
    required this.id,
    required this.playerId,
    required this.score,
    required this.createdAt,
    this.rank,
  });

  factory ScoreSubmission.fromJson(Map<String, dynamic> json) {
    return ScoreSubmission(
      id: json['id'],
      playerId: json['player_id'],
      score: json['score'],
      createdAt: DateTime.parse(json['created_at']),
      rank: json['rank'],
    );
  }
}

class LeaderboardEntry {
  final String playerName;
  final int score;
  final DateTime createdAt;
  final int rank;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.createdAt,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      playerName: json['player_name'],
      score: json['score'],
      createdAt: DateTime.parse(json['created_at']),
      rank: json['rank'],
    );
  }
}

class LeaderboardService {
  final String baseUrl;
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  LeaderboardService({String? apiUrl}) 
    : baseUrl = apiUrl ?? _getApiUrl();

  // Enhanced API URL resolution with multiple fallback strategies
  static String _getApiUrl() {
    // Strategy 1: Check if runtime config exists (web only)
    if (kIsWeb) {
      try {
        // Check for window.API_URL set by config.js
        final jsContext = js.context;
        if (jsContext.hasProperty('API_URL')) {
          final apiUrlFromJs = jsContext['API_URL'];
          if (apiUrlFromJs != null && apiUrlFromJs.toString().isNotEmpty) {
            debugPrint('Using window.API_URL: $apiUrlFromJs');
            return apiUrlFromJs.toString();
          }
        }
      } catch (e) {
        debugPrint('Failed to get window.API_URL: $e');
      }
    }

    // Strategy 2: Use compile-time defined API_URL
    const compileTimeApiUrl = String.fromEnvironment('API_URL');
    if (compileTimeApiUrl.isNotEmpty) {
      debugPrint('Using compile-time API_URL: $compileTimeApiUrl');
      return compileTimeApiUrl;
    }

    // Strategy 3: Auto-detect based on current host (production)
    if (kIsWeb) {
      try {
        // Use js.context to access window.location safely
        final location = js.context['location'];
        if (location != null) {
          final currentHost = location['host']?.toString();
          if (currentHost != null && !currentHost.contains('localhost')) {
            // In production, try to auto-detect backend URL
            final protocol = location['protocol']?.toString();
            final autoApiUrl = '${protocol}//flame-intro-backend.${_extractDomain(currentHost)}';
            debugPrint('Auto-detected API URL: $autoApiUrl');
            return autoApiUrl;
          }
        }
      } catch (e) {
        debugPrint('Failed to auto-detect API URL: $e');
      }
    }

    // Strategy 4: Default fallback
    const defaultUrl = 'http://localhost:8000';
    debugPrint('Using default API_URL: $defaultUrl');
    return defaultUrl;
  }

  static String _extractDomain(String host) {
    // Extract domain from host (e.g., 'app.example.com' -> 'example.com')
    final parts = host.split('.');
    if (parts.length >= 2) {
      return parts.skip(parts.length - 2).join('.');
    }
    return host;
  }

  Future<Player?> createPlayer(String name) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/api/players'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'name': name}),
            )
            .timeout(_timeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return Player.fromJson(jsonDecode(response.body));
        }
        
        debugPrint('Failed to create player: ${response.statusCode} - ${response.body}');
        if (attempt == _maxRetries - 1) return null;
        await Future.delayed(_retryDelay);
      } catch (e) {
        debugPrint('Error creating player (attempt ${attempt + 1}/$_maxRetries): $e');
        if (attempt == _maxRetries - 1) return null;
        await Future.delayed(_retryDelay);
      }
    }
    return null;
  }

  Future<ScoreSubmission?> submitScore(int playerId, int score) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/api/scores'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'playerId': playerId,
                'score': score,
              }),
            )
            .timeout(_timeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return ScoreSubmission.fromJson(jsonDecode(response.body));
        }
        
        debugPrint('Failed to submit score: ${response.statusCode} - ${response.body}');
        if (attempt == _maxRetries - 1) return null;
        await Future.delayed(_retryDelay);
      } catch (e) {
        debugPrint('Error submitting score (attempt ${attempt + 1}/$_maxRetries): $e');
        if (attempt == _maxRetries - 1) return null;
        await Future.delayed(_retryDelay);
      }
    }
    return null;
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse('$baseUrl/api/leaderboard'))
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final leaderboard = data['leaderboard'] as List;
          
          return leaderboard
              .map((entry) => LeaderboardEntry.fromJson(entry))
              .toList();
        }
        
        debugPrint('Failed to get leaderboard: ${response.statusCode} - ${response.body}');
        if (attempt == _maxRetries - 1) return [];
        await Future.delayed(_retryDelay);
      } catch (e) {
        debugPrint('Error getting leaderboard (attempt ${attempt + 1}/$_maxRetries): $e');
        if (attempt == _maxRetries - 1) return [];
        await Future.delayed(_retryDelay);
      }
    }
    return [];
  }

  Future<bool> checkHealth() async {
    try {
      debugPrint('Health checking API at: $baseUrl/api/health');
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      
      final isHealthy = response.statusCode == 200;
      debugPrint('Health check result: $isHealthy (status: ${response.statusCode})');
      return isHealthy;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }
} 