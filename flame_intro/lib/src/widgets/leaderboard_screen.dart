import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final LeaderboardService leaderboardService;
  final VoidCallback onClose;

  const LeaderboardScreen({
    super.key,
    required this.leaderboardService,
    required this.onClose,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;
  List<LeaderboardEntry> _cachedLeaderboard = [];
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final isOnline = await widget.leaderboardService.checkHealth();
    _isOffline = !isOnline;
    
    _leaderboardFuture = widget.leaderboardService.getLeaderboard().then((data) {
      if (data.isNotEmpty) {
        _cachedLeaderboard = data;
      }
      return data;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int index) {
    final isTopThree = index < 3;
    final medalColors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: isTopThree
            ? Border.all(color: medalColors[index], width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTopThree ? medalColors[index] : Colors.grey[300],
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isTopThree ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.playerName,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(entry.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          // Score
          Text(
            '${entry.score}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xff184e77),
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent && 
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
        }
      },
      child: GestureDetector(
        onTap: widget.onClose,  // Close on backdrop tap
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {}, // Prevent tap from propagating to backdrop
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LEADERBOARD',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close),
                          color: const Color(0xff184e77),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Leaderboard content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadLeaderboard,
                        child: FutureBuilder<List<LeaderboardEntry>>(
                          future: _leaderboardFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff184e77),
                                ),
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                              final hasCache = _cachedLeaderboard.isNotEmpty;
                              if (_isOffline && hasCache) {
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Offline - Showing last known scores',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _cachedLeaderboard.length,
                                        itemBuilder: (context, index) {
                                          return _buildLeaderboardEntry(_cachedLeaderboard[index], index);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isOffline ? Icons.cloud_off : Icons.error_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _isOffline ? 'Offline Mode' : 'Unable to load leaderboard',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _loadLeaderboard,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final entries = snapshot.data!;
                            
                            return ListView.builder(
                              itemCount: entries.length,
                              itemBuilder: (context, index) {
                                return _buildLeaderboardEntry(entries[index], index);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 