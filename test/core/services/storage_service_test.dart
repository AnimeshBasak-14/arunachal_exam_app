import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arunachal_exam_app/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService - getAccountData', () {
    test('returns UserModel when valid complete JSON exists for key', () async {
      final userMap = {
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'phone': '9123456789',
        'profilePic': 'avatar_blue',
        'dob': '1995-05-15',
        'rating': 1500,
        'city': 'Naharlagun',
      };

      SharedPreferences.setMockInitialValues({
        'account_data_jane@example.com': jsonEncode(userMap),
      });
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      final result = storageService.getAccountData('jane@example.com');

      expect(result, isNotNull);
      expect(result!.name, 'Jane Doe');
      expect(result.email, 'jane@example.com');
      expect(result.phone, '9123456789');
      expect(result.profilePic, 'avatar_blue');
      expect(result.dob, '1995-05-15');
      expect(result.rating, 1500);
      expect(result.city, 'Naharlagun');
    });

    test('trims and lowercases emailOrPhone parameter when querying key', () async {
      final userMap = {
        'name': 'John Smith',
        'email': 'john@example.com',
        'phone': '9876543210',
      };

      SharedPreferences.setMockInitialValues({
        'account_data_john@example.com': jsonEncode(userMap),
      });
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      final result = storageService.getAccountData('  JOHN@EXAMPLE.COM  ');

      expect(result, isNotNull);
      expect(result!.name, 'John Smith');
      expect(result.email, 'john@example.com');
    });

    test('uses default fallback values when JSON fields are missing or null', () async {
      final partialMap = <String, dynamic>{
        'name': 'Partial User',
      };

      SharedPreferences.setMockInitialValues({
        'account_data_partial@example.com': jsonEncode(partialMap),
      });
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      final result = storageService.getAccountData('partial@example.com');

      expect(result, isNotNull);
      expect(result!.name, 'Partial User');
      expect(result.email, 'partial@example.com'); // falls back to passed emailOrPhone
      expect(result.phone, '9876543210'); // default fallback
      expect(result.profilePic, 'avatar_green'); // default fallback
      expect(result.dob, '2000-01-01'); // default fallback
      expect(result.rating, 1200); // default fallback
      expect(result.city, 'Itanagar'); // default fallback
    });

    test('returns null when account data does not exist in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      final result = storageService.getAccountData('nonexistent@example.com');

      expect(result, isNull);
    });

    test('returns null when JSON parsing fails due to corrupted JSON string', () async {
      SharedPreferences.setMockInitialValues({
        'account_data_corrupt@example.com': '{invalid_json_string',
      });
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      final result = storageService.getAccountData('corrupt@example.com');

      expect(result, isNull);
    });

    test('returns null when stored JSON is not a Map (e.g. JSON array)', () async {
      SharedPreferences.setMockInitialValues({
        'account_data_array@example.com': '["item1", "item2"]',
      });
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      final result = storageService.getAccountData('array@example.com');

      expect(result, isNull);
    });

    test('retrieves user saved via saveUser (round-trip persistence)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      await storageService.saveUser(
        name: 'Alice',
        email: 'alice@example.com',
        phone: '9998887770',
        profilePic: 'avatar_purple',
        dob: '1998-12-25',
        rating: 1350,
        city: 'Pasighat',
      );

      final retrievedByEmail = storageService.getAccountData('alice@example.com');
      expect(retrievedByEmail, isNotNull);
      expect(retrievedByEmail!.name, 'Alice');
      expect(retrievedByEmail.email, 'alice@example.com');
      expect(retrievedByEmail.phone, '9998887770');
      expect(retrievedByEmail.profilePic, 'avatar_purple');
      expect(retrievedByEmail.dob, '1998-12-25');
      expect(retrievedByEmail.rating, 1350);
      expect(retrievedByEmail.city, 'Pasighat');

      final retrievedByPhone = storageService.getAccountData('9998887770');
      expect(retrievedByPhone, isNotNull);
      expect(retrievedByPhone!.name, 'Alice');
    });
  });
}
