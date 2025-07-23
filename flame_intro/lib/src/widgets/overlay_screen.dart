import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OverlayScreen extends StatelessWidget {
  const OverlayScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.showLeaderboard = false,
    this.onLeaderboardPressed,
  });

  final String title;
  final String subtitle;
  final bool showLeaderboard;
  final VoidCallback? onLeaderboardPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: const Alignment(0, -0.15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.displayLarge!.copyWith(),
          ).animate().slideY(duration: 750.ms, begin: -3, end: 0),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(),
            textAlign: TextAlign.center,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 1.seconds)
              .then()
              .fadeOut(duration: 1.seconds),
          if (showLeaderboard && onLeaderboardPressed != null) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onLeaderboardPressed,
              icon: const Icon(Icons.emoji_events),
              label: const Text('VIEW LEADERBOARD'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff184e77),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
          ],
        ],
      ),
    );
  }
}