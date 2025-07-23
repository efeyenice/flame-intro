import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../brick_breaker.dart';
import '../config.dart';
import 'overlay_screen.dart';                                   // Add this import
import 'score_card.dart';                                       // And this one too
import 'player_name_input.dart';
import 'leaderboard_screen.dart';

class GameApp extends StatefulWidget {                          // Modify this line
  const GameApp({super.key});

  @override                                                     // Add from here...
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  late final BrickBreaker game;
  String? playerName;
  bool showPlayerInput = true;
  bool showLeaderboard = false;
  bool isOffline = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    game = BrickBreaker();
    game.onGameStart = _onGameStart;
    game.onScoreSubmitted = _onScoreSubmitted;
    _checkOfflineStatus();
  }                                                             // To here.

  Future<void> _checkOfflineStatus() async {
    final isOnline = await game.leaderboardService.checkHealth();
    setState(() {
      isOffline = !isOnline;
    });
  }

  void _onScoreSubmitted(bool success, int? rank) {
    String message;
    if (success) {
      message = 'Score submitted! Rank: #${rank ?? 'N/A'}';
    } else {
      message = 'Failed to submit score - Offline mode';
    }
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onGameStart() {
    if (showLeaderboard) {
      setState(() {
        showLeaderboard = false;
      });
    }
  }

  void _onPlayerNameSubmit(String name) {
    setState(() {
      playerName = name;
      showPlayerInput = false;
      game.playerName = name;
    });
    
    // Create player session in the background
    game.leaderboardService.createPlayer(name).then((player) {
      if (player != null) {
        game.playerId = player.id;
        debugPrint('Player created with ID: ${player.id}');
      } else {
        debugPrint('Failed to create player session - playing offline');
      }
    });
  }

  void _toggleLeaderboard() {
    debugPrint('Toggling leaderboard. Current state: $showLeaderboard');
    setState(() {
      showLeaderboard = !showLeaderboard;
    });
    debugPrint('New leaderboard state: $showLeaderboard');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.pressStart2pTextTheme().apply(
          bodyColor: const Color(0xff184e77),
          displayColor: const Color(0xff184e77),
        ),
      ),
      home: Scaffold(
        key: _scaffoldMessengerKey,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xffa9d6e5), Color(0xfff2e8cf)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: showPlayerInput
                  ? PlayerNameInput(onSubmit: _onPlayerNameSubmit)
                  : Stack(
                      children: [
                        Center(
                          child: Column(                                  // Modify from here...
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: ScoreCard(score: game.score),
                                  ),
                                  if (isOffline)
                                    IconButton(
                                      onPressed: _checkOfflineStatus,
                                      icon: const Icon(Icons.cloud_off, color: Colors.red),
                                      tooltip: 'Offline - Tap to retry',
                                    ),
                                  IconButton(
                                    onPressed: _toggleLeaderboard,
                                    icon: const Icon(Icons.emoji_events),
                                    color: const Color(0xff184e77),
                                    iconSize: 32,
                                    tooltip: 'View Leaderboard',
                                  ),
                                ],
                              ),
                              Expanded(
                                child: FittedBox(
                                  child: SizedBox(
                                    width: gameWidth,
                                    height: gameHeight,
                                    child: GameWidget(
                                      game: game,
                                      overlayBuilderMap: {
                                        PlayState.welcome.name: (context, game) =>
                                            OverlayScreen(
                                              title: 'TAP TO PLAY',
                                              subtitle: 'Welcome, $playerName!',
                                              showLeaderboard: true,
                                              onLeaderboardPressed: _toggleLeaderboard,
                                            ),
                                        PlayState.gameOver.name: (context, game) =>
                                            ValueListenableBuilder<int?>(
                                              valueListenable: this.game.submittedRank,
                                              builder: (context, rank, child) {
                                                String subtitle = 'Tap to Play Again';
                                                if (rank != null) {
                                                  subtitle = 'You ranked #$rank!\n$subtitle';
                                                } else if (isOffline) {
                                                  subtitle = 'Offline - Score not submitted\n$subtitle';
                                                }
                                                return OverlayScreen(
                                                  title: 'G A M E   O V E R',
                                                  subtitle: subtitle,
                                                  showLeaderboard: true,
                                                  onLeaderboardPressed: _toggleLeaderboard,
                                                );
                                              },
                                            ),
                                        PlayState.won.name: (context, game) =>
                                            ValueListenableBuilder<int?>(
                                              valueListenable: this.game.submittedRank,
                                              builder: (context, rank, child) {
                                                String subtitle = 'Tap to Play Again';
                                                if (rank != null) {
                                                  subtitle = 'You ranked #$rank!\n$subtitle';
                                                } else if (isOffline) {
                                                  subtitle = 'Offline - Score not submitted\n$subtitle';
                                                }
                                                return OverlayScreen(
                                                  title: 'Y O U   W O N ! ! !',
                                                  subtitle: subtitle,
                                                  showLeaderboard: true,
                                                  onLeaderboardPressed: _toggleLeaderboard,
                                                );
                                              },
                                            ),
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),                                              // To here.
                        ),
                        if (showLeaderboard)
                          LeaderboardScreen(
                            leaderboardService: game.leaderboardService,
                            onClose: _toggleLeaderboard,
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}