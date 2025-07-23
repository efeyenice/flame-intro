import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LeaderboardEntry {
  final int rank;
  final String playerName;
  final int score;
  final DateTime date;

  LeaderboardEntry({
    required this.rank,
    required this.playerName,
    required this.score,
    required this.date,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      playerName: json['playerName'],
      score: json['score'],
      date: DateTime.parse(json['date']),
    );
  }
}

class Player {
  final int id;
  final String name;

  Player({required this.id, required this.name});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
    );
  }
}

class ScoreSubmission {
  final int id;
  final int playerId;
  final int score;
  final int rank;

  ScoreSubmission({
    required this.id,
    required this.playerId,
    required this.score,
    required this.rank,
  });

  factory ScoreSubmission.fromJson(Map<String, dynamic> json) {
    return ScoreSubmission(
      id: json['id'],
      playerId: json['playerId'],
      score: json['score'],
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
    : baseUrl = apiUrl ?? const String.fromEnvironment(
        'API_URL',
        defaultValue: 'http://localhost:8000',
      );

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
        debugPrint('Error creating player: $e');
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
        debugPrint('Error submitting score: $e');
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
        debugPrint('Error getting leaderboard: $e');
        if (attempt == _maxRetries - 1) return [];
        await Future.delayed(_retryDelay);
      }
    }
    return [];
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }
} 