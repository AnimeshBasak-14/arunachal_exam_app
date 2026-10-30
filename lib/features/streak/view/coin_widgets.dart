import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/aura.dart';
import '../../../core/widgets/aura/wordmark.dart';
import '../data/coins.dart';

/// The Dawnlit coin: a soft disc with the Z mark. Same palette as the app,
/// no flames.
class CoinMark extends StatelessWidget {
  final double size;
  const CoinMark({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: a.tint,
        border: Border.all(
            color: a.accent.withValues(alpha: 0.35), width: size * 0.06),
      ),
      child: ZapMark(size: size * 0.62, color: a.accent),
    );
  }
}

/// Coin balance next to the notification bell. Opens the streak page.
class CoinPill extends ConsumerWidget {
  const CoinPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.aura;
    final balance = ref.watch(coinsProvider).balance;
    return Semantics(
      button: true,
      label: 'Streak and coins. $balance coins.',
      excludeSemantics: true,
      child: Material(
        color: a.surface,
        shape: StadiumBorder(side: BorderSide(color: a.hairline)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => context.push('/streak'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.15,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CoinMark(size: 24),
                    const SizedBox(width: 7),
                    Text('$balance',
                        style: AuraType.digits(14, a.ink,
                            weight: FontWeight.w600)),
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

/// A small coin tucked into a screen. It only appears on the days and
/// screens chosen for hidden coins, and only until it has been collected.
class HiddenCoin extends ConsumerStatefulWidget {
  final String spot;
  const HiddenCoin(this.spot, {super.key});

  @override
  ConsumerState<HiddenCoin> createState() => _HiddenCoinState();
}

class _HiddenCoinState extends ConsumerState<HiddenCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _collect() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    final won = ref.read(coinsProvider.notifier).award(
        hiddenCoinKey(now, widget.spot), CoinReward.hiddenCoin, 'Hidden coin');
    if (won) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('You found a hidden coin. +${CoinReward.hiddenCoin}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    ref.watch(coinsProvider); // hide once collected
    final active = hiddenSpotsFor(now).contains(widget.spot) &&
        !ref.read(coinsProvider.notifier).has(hiddenCoinKey(now, widget.spot));
    if (!active) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: 'Hidden coin. Tap to collect.',
      child: InkResponse(
        onTap: _collect,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: FadeTransition(
              opacity: Tween(begin: 0.45, end: 0.95).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
              child: const CoinMark(size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
