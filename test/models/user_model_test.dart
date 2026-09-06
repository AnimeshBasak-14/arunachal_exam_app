import 'package:flutter_test/flutter_test.dart';
import 'package:arunachal_exam_app/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('instantiates with default values for optional parameters', () {
      final user = UserModel(
        name: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
      );

      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '1234567890');
      expect(user.profilePic, isNull);
      expect(user.dob, '2000-01-01');
      expect(user.rating, 0);
      expect(user.city, '');
    });

    test('instantiates with custom values for all parameters', () {
      final user = UserModel(
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '0987654321',
        profilePic: 'https://example.com/pic.png',
        dob: '1995-05-15',
        rating: 1500,
        city: 'Itanagar',
      );

      expect(user.name, 'Jane Doe');
      expect(user.email, 'jane@example.com');
      expect(user.phone, '0987654321');
      expect(user.profilePic, 'https://example.com/pic.png');
      expect(user.dob, '1995-05-15');
      expect(user.rating, 1500);
      expect(user.city, 'Itanagar');
    });

    group('copyWith', () {
      final initialUser = UserModel(
        name: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
        profilePic: 'https://example.com/pic.png',
        dob: '1990-01-01',
        rating: 1300,
        city: 'Naharlagun',
      );

      test('returns same object when no arguments are passed', () {
        final updatedUser = initialUser.copyWith();

        expect(updatedUser.name, initialUser.name);
        expect(updatedUser.email, initialUser.email);
        expect(updatedUser.phone, initialUser.phone);
        expect(updatedUser.profilePic, initialUser.profilePic);
        expect(updatedUser.dob, initialUser.dob);
        expect(updatedUser.rating, initialUser.rating);
        expect(updatedUser.city, initialUser.city);
      });

      test('updates single properties correctly', () {
        final updatedName = initialUser.copyWith(name: 'John Updated');
        expect(updatedName.name, 'John Updated');
        expect(updatedName.email, initialUser.email);

        final updatedEmail = initialUser.copyWith(email: 'newemail@example.com');
        expect(updatedEmail.email, 'newemail@example.com');
        expect(updatedEmail.name, initialUser.name);

        final updatedPhone = initialUser.copyWith(phone: '1112223333');
        expect(updatedPhone.phone, '1112223333');

        final updatedProfilePic = initialUser.copyWith(profilePic: 'https://example.com/new.png');
        expect(updatedProfilePic.profilePic, 'https://example.com/new.png');

        final updatedDob = initialUser.copyWith(dob: '1992-02-02');
        expect(updatedDob.dob, '1992-02-02');

        final updatedRating = initialUser.copyWith(rating: 1400);
        expect(updatedRating.rating, 1400);

        final updatedCity = initialUser.copyWith(city: 'Pasighat');
        expect(updatedCity.city, 'Pasighat');
      });

      test('updates multiple properties at once', () {
        final updatedUser = initialUser.copyWith(
          name: 'Jane Smith',
          rating: 1600,
          city: 'Tawang',
        );

        expect(updatedUser.name, 'Jane Smith');
        expect(updatedUser.rating, 1600);
        expect(updatedUser.city, 'Tawang');
        expect(updatedUser.email, initialUser.email);
        expect(updatedUser.phone, initialUser.phone);
        expect(updatedUser.profilePic, initialUser.profilePic);
        expect(updatedUser.dob, initialUser.dob);
      });
    });
  });
}
