import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arunachal_exam_app/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Benchmark saveUser performance over multiple iterations', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);

    const iterations = 1000;
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      await storageService.saveUser(
        name: 'User $i',
        email: 'user$i@arunachal.in',
        phone: '987654321$i',
        profilePic: 'avatar_green',
        dob: '2000-01-01',
        rating: 1200 + i,
        city: 'Itanagar',
      );
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;
    final avgUs = (stopwatch.elapsedMicroseconds / iterations).toStringAsFixed(2);

    // ignore: avoid_print
    print('Benchmark Result: $iterations iterations of saveUser took ${elapsedMs}ms (Avg: $avgUsµs per call)');
  });
}
