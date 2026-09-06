import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arunachal_exam_app/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService - Secure Password Tests', () {
    late SharedPreferences prefs;
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      FlutterSecureStorage.setMockInitialValues({});
      storageService = StorageService(prefs, const FlutterSecureStorage());
    });

    test('registerUserAccount stores password securely in secure storage and not in SharedPreferences', () async {
      await storageService.registerUserAccount(
        emailOrPhone: 'user@gmail.com',
        password: 'securePassword123',
        name: 'Test User',
      );

      final retrieved = await storageService.getRegisteredPassword('user@gmail.com');
      expect(retrieved, equals('securePassword123'));

      // Ensure password key is NOT in SharedPreferences
      expect(prefs.containsKey('reg_pwd_user@gmail.com'), isFalse);
    });

    test('getRegisteredPassword migrates legacy plaintext password from SharedPreferences to secure storage', () async {
      // Manually set legacy password in SharedPreferences
      await prefs.setString('reg_pwd_legacy@gmail.com', 'oldLegacyPwd');
      expect(prefs.containsKey('reg_pwd_legacy@gmail.com'), isTrue);

      // Call getRegisteredPassword, which should migrate it
      final retrieved = await storageService.getRegisteredPassword('legacy@gmail.com');
      expect(retrieved, equals('oldLegacyPwd'));

      // Ensure legacy password was deleted from SharedPreferences
      expect(prefs.containsKey('reg_pwd_legacy@gmail.com'), isFalse);

      // Verify it is now in secure storage
      const secureStorage = FlutterSecureStorage();
      final secureVal = await secureStorage.read(key: 'reg_pwd_legacy@gmail.com');
      expect(secureVal, equals('oldLegacyPwd'));
    });

    test('updateRegisteredPassword updates password securely in secure storage', () async {
      await storageService.registerUserAccount(
        emailOrPhone: 'user@gmail.com',
        password: 'initialPwd',
        name: 'Test User',
      );

      await storageService.updateRegisteredPassword('user@gmail.com', 'updatedPwd456');

      final retrieved = await storageService.getRegisteredPassword('user@gmail.com');
      expect(retrieved, equals('updatedPwd456'));
      expect(prefs.containsKey('reg_pwd_user@gmail.com'), isFalse);
    });

    test('updateRegisteredAccount updates account key and transfers secure password', () async {
      await storageService.registerUserAccount(
        emailOrPhone: 'old@gmail.com',
        password: 'myPassword',
        name: 'Old Name',
      );

      await storageService.updateRegisteredAccount(
        'old@gmail.com',
        'new@gmail.com',
        'New Name',
        '2000-01-01',
        0,
      );

      expect(await storageService.getRegisteredPassword('old@gmail.com'), isNull);
      expect(await storageService.getRegisteredPassword('new@gmail.com'), equals('myPassword'));
    });
  });
}
