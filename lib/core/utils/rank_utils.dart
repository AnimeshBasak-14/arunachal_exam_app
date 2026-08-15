import 'package:flutter/material.dart';

class RankTier {
  final String name;
  final String title;
  final int minRating;
  final Color color;
  final IconData icon;
  final String badgeText;

  const RankTier({
    required this.name,
    required this.title,
    required this.minRating,
    required this.color,
    required this.icon,
    required this.badgeText,
  });
}

class RankUtils {
  static const List<RankTier> tiers = [
    RankTier(
      name: 'Mythical Glory',
      title: 'Mythical Glory 🌟',
      minRating: 2000,
      color: Color(0xFFFFD700),
      icon: Icons.workspace_premium_rounded,
      badgeText: 'GLORY',
    ),
    RankTier(
      name: 'Mythic',
      title: 'Mythic 👑',
      minRating: 1750,
      color: Color(0xFFEF4444),
      icon: Icons.military_tech_rounded,
      badgeText: 'MYTHIC',
    ),
    RankTier(
      name: 'Legend',
      title: 'Legend ⚔️',
      minRating: 1600,
      color: Color(0xFF8B5CF6),
      icon: Icons.shield_rounded,
      badgeText: 'LEGEND',
    ),
    RankTier(
      name: 'Epic',
      title: 'Epic ⚡',
      minRating: 1500,
      color: Color(0xFF06B6D4),
      icon: Icons.flash_on_rounded,
      badgeText: 'EPIC',
    ),
    RankTier(
      name: 'Grandmaster',
      title: 'Grandmaster 🛡️',
      minRating: 1400,
      color: Color(0xFF10B981),
      icon: Icons.verified_user_rounded,
      badgeText: 'GM',
    ),
    RankTier(
      name: 'Master',
      title: 'Master 🎖️',
      minRating: 1300,
      color: Color(0xFFF59E0B),
      icon: Icons.stars_rounded,
      badgeText: 'MASTER',
    ),
    RankTier(
      name: 'Elite',
      title: 'Elite 🥈',
      minRating: 1230,
      color: Color(0xFF94A3B8),
      icon: Icons.military_tech_outlined,
      badgeText: 'ELITE',
    ),
    RankTier(
      name: 'Warrior',
      title: 'Warrior 🗡️',
      minRating: 0,
      color: Color(0xFFB45309),
      icon: Icons.shield_outlined,
      badgeText: 'WARRIOR',
    ),
  ];

  static RankTier getTier(int rating) {
    for (final tier in tiers) {
      if (rating >= tier.minRating) {
        return tier;
      }
    }
    return tiers.last;
  }

  static String getTierName(int rating) => getTier(rating).name;
  static String getTierTitle(int rating) => getTier(rating).title;
  static Color getTierColor(int rating) => getTier(rating).color;
  static IconData getTierIcon(int rating) => getTier(rating).icon;
}
