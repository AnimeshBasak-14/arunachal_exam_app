import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared provider for dynamic text scaling across reading-heavy screens.
/// Default: 1.0 (normal). Controlled steps: 0.85, 0.92, 1.0, 1.10, 1.20, 1.35.
class TextScaleNotifier extends Notifier<double> {
  @override
  double build() => 1.0;

  void set(double scale) => state = scale;
}

final textScaleProvider = NotifierProvider<TextScaleNotifier, double>(
  TextScaleNotifier.new,
);
