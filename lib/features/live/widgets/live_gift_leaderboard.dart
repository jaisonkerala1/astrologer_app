import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/theme/services/theme_service.dart';

/// Gift leaderboard overlay showing top supporters
class LiveGiftLeaderboard extends StatefulWidget {
  final List<LeaderboardEntry> entries;
  final VoidCallback onClose;
  final String streamTitle;

  const LiveGiftLeaderboard({
    super.key,
    required this.entries,
    required this.onClose,
    required this.streamTitle,
  });

  @override
  State<LiveGiftLeaderboard> createState() => _LiveGiftLeaderboardState();
}

class _LiveGiftLeaderboardState extends State<LiveGiftLeaderboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    HapticFeedback.selectionClick();
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: _handleClose,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: SlideTransition(
              position: _slideAnimation,
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {}, // Prevent tap from closing when tapping content
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.95),
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(-5, 0),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          _buildHeader(themeService),
                          Expanded(
                            child: widget.entries.isEmpty
                                ? _buildEmptyState()
                                : _buildLeaderboardList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFF8C00).withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFF8C00),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Supporters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.streamTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _handleClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.entries.length,
      itemBuilder: (context, index) {
        return _buildLeaderboardEntry(
          widget.entries[index],
          index + 1,
        );
      },
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int rank) {
    final isTopThree = rank <= 3;
    final rankColor = _getRankColor(rank);
    final rankEmoji = _getRankEmoji(rank);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isTopThree
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  rankColor.withOpacity(0.2),
                  rankColor.withOpacity(0.05),
                ],
              )
            : null,
        color: isTopThree ? null : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopThree
              ? rankColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: isTopThree ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: isTopThree
                ? Text(
                    rankEmoji,
                    style: const TextStyle(fontSize: 32),
                    textAlign: TextAlign.center,
                  )
                : Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  rankColor.withOpacity(0.8),
                  rankColor.withOpacity(0.5),
                ],
              ),
              border: Border.all(
                color: rankColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                entry.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isTopThree) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified,
                        color: rankColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.giftCount} gifts',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Total amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${entry.totalAmount}',
                style: TextStyle(
                  color: rankColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (entry.topGiftEmoji.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  entry.topGiftEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🎁',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'No gifts yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to send a gift!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.white;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final int totalAmount;
  final int giftCount;
  final String topGiftEmoji;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.totalAmount,
    required this.giftCount,
    this.topGiftEmoji = '',
  });
}

