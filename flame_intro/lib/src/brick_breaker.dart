import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/components.dart';
import 'config.dart';
import 'services/leaderboard_service.dart';

enum PlayState { welcome, playing, gameOver, won }

class BrickBreaker extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector {
  BrickBreaker()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: gameWidth,
          height: gameHeight,
        ),
      );

  final ValueNotifier<int> score = ValueNotifier(0);            // Add this line
  final ValueNotifier<int?> submittedRank = ValueNotifier(null);
  final rand = math.Random();
  double get width => size.x;
  double get height => size.y;
  
  String? playerName;
  int? playerId;
  final leaderboardService = LeaderboardService();
  bool _scoreSubmitted = false;
  Function()? onGameStart;
  Function(bool success, int? rank)? onScoreSubmitted;

  late PlayState _playState;
  PlayState get playState => _playState;
  set playState(PlayState playState) {
    _playState = playState;
    switch (playState) {
      case PlayState.welcome:
      case PlayState.gameOver:
      case PlayState.won:
        overlays.add(playState.name);
        // Submit score when game ends
        if ((playState == PlayState.gameOver || playState == PlayState.won) && 
            !_scoreSubmitted && 
            playerId != null && 
            score.value > 0) {
          _submitScore();
        }
      case PlayState.playing:
        overlays.remove(PlayState.welcome.name);
        overlays.remove(PlayState.gameOver.name);
        overlays.remove(PlayState.won.name);
    }
  }

  Future<void> _submitScore() async {
    if (_scoreSubmitted || playerId == null) {
      onScoreSubmitted?.call(false, null);
      return;
    }
    
    _scoreSubmitted = true;
    debugPrint('Submitting score: ${score.value} for player $playerId');
    
    final result = await leaderboardService.submitScore(playerId!, score.value);
    
    if (result != null) {
      debugPrint('Score submitted successfully! Rank: ${result.rank}');
      submittedRank.value = result.rank;
      onScoreSubmitted?.call(true, result.rank);
    } else {
      debugPrint('Failed to submit score');
      onScoreSubmitted?.call(false, null);
    }
  }

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(PlayArea());

    playState = PlayState.welcome;
  }

  void startGame() {
    if (playState == PlayState.playing) return;

    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Bat>());
    world.removeAll(world.children.query<Brick>());

    playState = PlayState.playing;
    score.value = 0;                                            // Add this line
    _scoreSubmitted = false;  // Reset score submission flag
    submittedRank.value = null;  // Reset rank
    
    // Notify UI that game has started
    onGameStart?.call();

    world.add(
      Ball(
        difficultyModifier: difficultyModifier,
        radius: ballRadius,
        position: size / 2,
        velocity: Vector2(
          (rand.nextDouble() - 0.5) * width,
          height * 0.2,
        ).normalized()..scale(height / 4),
      ),
    );

    world.add(
      Bat(
        size: Vector2(batWidth, batHeight),
        cornerRadius: const Radius.circular(ballRadius / 2),
        position: Vector2(width / 2, height * 0.95),
      ),
    );

    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
        for (var j = 1; j <= 5; j++)
          Brick(
            position: Vector2(
              (i + 0.5) * brickWidth + (i + 1) * brickGutter,
              (j + 2.0) * brickHeight + j * brickGutter,
            ),
            color: brickColors[i],
          ),
    ]);
  }

  @override
  void onTap() {
    super.onTap();
    startGame();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        world.children.query<Bat>().first.moveBy(-batStep);
      case LogicalKeyboardKey.arrowRight:
        world.children.query<Bat>().first.moveBy(batStep);
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        startGame();
    }
    return KeyEventResult.handled;
  }

  @override
  Color backgroundColor() => const Color(0xfff2e8cf);
}