import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/core/utils/rank_utils.dart';

void main() {
  group('RankUtils', () {
    group('getTier', () {
      test('returns correct tier at exact minimum rating thresholds', () {
        expect(RankUtils.getTier(2000).name, equals('Mythical Glory'));
        expect(RankUtils.getTier(1750).name, equals('Mythic'));
        expect(RankUtils.getTier(1600).name, equals('Legend'));
        expect(RankUtils.getTier(1500).name, equals('Epic'));
        expect(RankUtils.getTier(1400).name, equals('Grandmaster'));
        expect(RankUtils.getTier(1300).name, equals('Master'));
        expect(RankUtils.getTier(1230).name, equals('Elite'));
        expect(RankUtils.getTier(0).name, equals('Warrior'));
      });

      test('returns correct tier for intermediate rating values', () {
        expect(RankUtils.getTier(2500).name, equals('Mythical Glory'));
        expect(RankUtils.getTier(1800).name, equals('Mythic'));
        expect(RankUtils.getTier(1650).name, equals('Legend'));
        expect(RankUtils.getTier(1550).name, equals('Epic'));
        expect(RankUtils.getTier(1450).name, equals('Grandmaster'));
        expect(RankUtils.getTier(1350).name, equals('Master'));
        expect(RankUtils.getTier(1250).name, equals('Elite'));
        expect(RankUtils.getTier(500).name, equals('Warrior'));
      });

      test('returns Warrior tier for negative rating values', () {
        expect(RankUtils.getTier(-100).name, equals('Warrior'));
      });
    });

    group('helper methods', () {
      test('getTierName returns correct tier name', () {
        expect(RankUtils.getTierName(2000), equals('Mythical Glory'));
        expect(RankUtils.getTierName(0), equals('Warrior'));
      });

      test('getTierTitle returns correct tier title', () {
        expect(RankUtils.getTierTitle(2000), equals('Mythical Glory 🌟'));
        expect(RankUtils.getTierTitle(0), equals('Warrior 🗡️'));
      });

      test('getTierColor returns correct tier color', () {
        expect(RankUtils.getTierColor(2000), equals(const Color(0xFFFFD700)));
        expect(RankUtils.getTierColor(0), equals(const Color(0xFFB45309)));
      });

      test('getTierIcon returns correct tier icon', () {
        expect(RankUtils.getTierIcon(2000), equals(Icons.workspace_premium_rounded));
        expect(RankUtils.getTierIcon(0), equals(Icons.shield_outlined));
      });
    });

    group('tiers list integrity', () {
      test('tiers list is sorted in descending order of minRating', () {
        for (int i = 0; i < RankUtils.tiers.length - 1; i++) {
          expect(
            RankUtils.tiers[i].minRating,
            greaterThan(RankUtils.tiers[i + 1].minRating),
          );
        }
      });
    });
  });
}
