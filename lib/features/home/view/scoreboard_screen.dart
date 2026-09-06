import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/rank_utils.dart';
import '../../../core/utils/avatar_utils.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

// Simulated global competitors
final _mockCompetitors = [
  {
    'name': 'Tenzin Dorje',
    'email': 'tenzin@gmail.com',
    'rating': 2200,
    'state': 'Tawang'
  },
  {
    'name': 'Mepung Loyi',
    'email': 'mepung@gmail.com',
    'rating': 2000,
    'state': 'Itanagar'
  },
  {
    'name': 'Geyum Riba',
    'email': 'geyum@gmail.com',
    'rating': 1900,
    'state': 'Pasighat'
  },
  {
    'name': 'Chukhu Takia',
    'email': 'chukhu@gmail.com',
    'rating': 1750,
    'state': 'Naharlagun'
  },
  {
    'name': 'Nabam Riram',
    'email': 'nabam@gmail.com',
    'rating': 1600,
    'state': 'Ziro'
  },
  {
    'name': 'Koj Naro',
    'email': 'koj@gmail.com',
    'rating': 1450,
    'state': 'Along'
  },
  {
    'name': 'Bamang Tago',
    'email': 'bamang@gmail.com',
    'rating': 1300,
    'state': 'Bomdila'
  },
  {
    'name': 'Likha Pul',
    'email': 'likha@gmail.com',
    'rating': 1150,
    'state': 'Roing'
  },
  {
    'name': 'Talom Rupam',
    'email': 'talom@gmail.com',
    'rating': 1000,
    'state': 'Seppa'
  },
  {
    'name': 'Dungey Karga',
    'email': 'dungey@gmail.com',
    'rating': 850,
    'state': 'Tezu'
  },
  {
    'name': 'Yomge Ete',
    'email': 'yomge@gmail.com',
    'rating': 700,
    'state': 'Daporijo'
  },
  {
    'name': 'Oken Tayeng',
    'email': 'oken@gmail.com',
    'rating': 550,
    'state': 'Changlang'
  },
  {
    'name': 'Mudang Komo',
    'email': 'mudang@gmail.com',
    'rating': 400,
    'state': 'Longding'
  },
  {
    'name': 'Hano Tara',
    'email': 'hano@gmail.com',
    'rating': 250,
    'state': 'Yupia'
  },
  {
    'name': 'Jorum Bam',
    'email': 'jorum@gmail.com',
    'rating': 150,
    'state': 'Basar'
  },
];

final globalLeaderboardStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('rating', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) {
      return _mockCompetitors;
    }
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['name'] ?? 'Unknown',
        'email': data['email'] ?? '',
        'rating': data['rating'] ?? 0,
        'state': data['city'] ?? 'Unknown',
        'profilePic': data['profilePic'] ?? '',
      };
    }).toList();
  });
});

/// Helper data class for sorted leaderboard state
class LeaderboardData {
  final List<Map<String, dynamic>> allEntries;
  final int myRank;
  final List<Map<String, dynamic>> topThree;

  const LeaderboardData({
    required this.allEntries,
    required this.myRank,
    required this.topThree,
  });
}

final leaderboardProvider = Provider.autoDispose<LeaderboardData>((ref) {
  final currentUser = ref.watch(authViewModelProvider).user;
  final userEmail = currentUser?.email ?? '';
  final userRating = currentUser?.rating ?? 0;
  final userName = currentUser?.name ?? 'You';

  final asyncLeaderboard = ref.watch(globalLeaderboardStreamProvider);
  
  List<Map<String, dynamic>> rawEntries = asyncLeaderboard.value ?? _mockCompetitors;

  bool foundMe = false;
  final allEntries = rawEntries.map((e) {
    final entry = Map<String, dynamic>.from(e);
    if (entry['email'] == userEmail && userEmail.isNotEmpty) {
      entry['isMe'] = true;
      foundMe = true;
      entry['profilePic'] = currentUser?.profilePic ?? entry['profilePic'] ?? '';
    } else {
      entry['isMe'] = false;
      entry['profilePic'] = entry['profilePic'] ?? '';
    }
    return entry;
  }).toList();

  if (!foundMe && userEmail.isNotEmpty) {
    allEntries.add({
      'name': userName,
      'email': userEmail,
      'rating': userRating,
      'state': currentUser?.city ?? 'Me',
      'isMe': true,
      'profilePic': currentUser?.profilePic ?? '',
    });
  }

  // O(N log N) sort operation offloaded from Widget.build()
  allEntries.sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));

  final myRank = allEntries.indexWhere((e) => e['isMe'] == true) + 1;
  final topThree = allEntries.take(3).toList();

  return LeaderboardData(
    allEntries: allEntries,
    myRank: myRank,
    topThree: topThree,
  );
});

String _rankSuffix(int rank) {
  if (rank == 1) return '🥇';
  if (rank == 2) return '🥈';
  if (rank == 3) return '🥉';
  return '#$rank';
}

class ScoreboardScreen extends ConsumerWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authViewModelProvider).user;
    final userRating = currentUser?.rating ?? 0;

    final userTier = RankUtils.getTier(userRating);

    // ⚡ Fetch memoized leaderboard calculations from Riverpod provider
    final leaderboard = ref.watch(leaderboardProvider);
    final allEntries = leaderboard.allEntries;
    final myRank = leaderboard.myRank;
    final topThree = leaderboard.topThree;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Global Scoreboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Trophy History',
            onPressed: () => context.push('/trophy-history'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // ── PODIUM ───────────────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F6F4A), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
            ),
            child: Column(
              children: [
                const Text(
                  'TOP COMPETITORS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2nd place
                    if (topThree.length > 1)
                      _buildPodiumEntry(topThree[1], 2, 70),
                    // 1st place
                    if (topThree.isNotEmpty)
                      _buildPodiumEntry(topThree[0], 1, 90),
                    // 3rd place
                    if (topThree.length > 2)
                      _buildPodiumEntry(topThree[2], 3, 55),
                  ],
                ),
              ],
            ),
          ),
          // ── MY RANK BANNER ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text(
                  'Rank #$myRank',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      fontSize: 13.5),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: userTier.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: userTier.color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      userTier.title,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: userTier.color),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$userRating 🏆',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── FULL LEADERBOARD ─────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 48,
              ),
              itemCount: allEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final entry = allEntries[index];
                final rank = index + 1;
                final isMe = entry['isMe'] == true;
                final rating = entry['rating'] as int;
                final tier = RankUtils.getTier(rating);

                return GestureDetector(
                  onTap: entry['isMe'] == true
                      ? null
                      : () => context.push('/public-profile', extra: entry),
                  child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primaryLight.withValues(alpha: 0.6)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    border: Border.all(
                      color: isMe
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.divider,
                      width: isMe ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 32,
                        child: rank <= 3
                            ? Text(
                                _rankSuffix(rank),
                                style: const TextStyle(fontSize: 18),
                                textAlign: TextAlign.center,
                              )
                            : Text(
                                '#$rank',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isMe
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
                      const SizedBox(width: 8),
                      // Avatar
                      _buildAvatarWidget(
                        entry['profilePic'] as String?,
                        entry['name'] as String,
                        radius: 17,
                        isMe: isMe,
                        fallbackColor: tier.color,
                      ),
                      const SizedBox(width: 8),
                      // Name and State
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe
                                  ? '${currentUser?.name ?? 'You'} (You)'
                                  : entry['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isMe
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: tier.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    tier.title,
                                    style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: tier.color),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    entry['state'] as String,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textHint),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Rating
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events_rounded,
                                  color: AppColors.accent, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '$rating',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const Text('Trophies',
                              style: TextStyle(
                                  fontSize: 9.5, color: AppColors.textHint)),
                        ],
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    ),
    ),
    );
  }

  
  Widget _buildAvatarWidget(String? profilePic, String name,
      {double radius = 17,
      bool isMe = false,
      Color fallbackColor = Colors.grey}) {
    final imageProvider = AvatarUtils.getAvatarImageProvider(profilePic);

    if (imageProvider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        backgroundImage: imageProvider,
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          isMe ? AppColors.primary : fallbackColor.withValues(alpha: 0.22),
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
          color: isMe ? Colors.white : fallbackColor,
        ),
      ),
    );
  }

  Widget _buildPodiumEntry(
      Map<String, dynamic> entry, int rank, double height) {
    final isMe = entry['isMe'] == true;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildAvatarWidget(
          entry['profilePic'] as String?,
          entry['name'] as String,
          radius: rank == 1 ? 26 : 20,
          isMe: isMe,
          fallbackColor: Colors.white,
        ),
        const SizedBox(height: 4),
        Text(
          isMe ? 'You' : (entry['name'] as String).split(' ').first,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(
          '${entry['rating']}',
          style: TextStyle(
              fontSize: 10, color: Colors.white.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 4),
        Container(
          width: rank == 1 ? 80 : 65,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              _rankSuffix(rank),
              style: TextStyle(fontSize: rank == 1 ? 28 : 22),
            ),
          ),
        ),
      ],
    );
  }
}
