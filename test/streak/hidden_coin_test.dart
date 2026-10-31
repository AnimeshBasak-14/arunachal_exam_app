import 'package:arunachal_exam_app/core/services/service_providers.dart';
import 'package:arunachal_exam_app/core/theme/app_theme.dart';
import 'package:arunachal_exam_app/features/streak/data/coins.dart';
import 'package:arunachal_exam_app/features/streak/view/coin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pump(WidgetTester tester, String spot) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: HiddenCoin(spot))),
    ),
  ));
  await tester.pump();
  return container;
}

void main() {
  testWidgets('a hidden coin on an active spot can be collected once',
      (tester) async {
    final spot = hiddenSpotsFor(DateTime.now()).first;
    final c = await pump(tester, spot);

    expect(
        find.bySemanticsLabel('Hidden coin. Tap to collect.'), findsOneWidget);
    await tester.tap(find.byType(HiddenCoin));
    await tester.pump();

    expect(c.read(coinsProvider).balance, CoinReward.hiddenCoin);
    expect(find.byType(CoinMark), findsNothing); // gone after collecting
    expect(find.textContaining('hidden coin'), findsOneWidget); // snackbar
  });

  testWidgets('nothing is shown on a spot without a coin today',
      (tester) async {
    final inactive = hiddenCoinSpots
        .firstWhere((s) => !hiddenSpotsFor(DateTime.now()).contains(s));
    final c = await pump(tester, inactive);

    expect(find.byType(CoinMark), findsNothing);
    expect(c.read(coinsProvider).balance, 0);
  });

  testWidgets('the coin pill shows the balance', (tester) async {
    SharedPreferences.setMockInitialValues({'coins_balance_v1': 48});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: CoinPill())),
      ),
    ));
    expect(find.text('48'), findsOneWidget);
    expect(
        find.bySemanticsLabel('Streak and coins. 48 coins.'), findsOneWidget);
  });
}
