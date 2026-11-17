import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_hub/models/user.dart';
import 'package:shopping_hub/services/database_helper.dart';

void main() {
  group('Authentication & Security Tests', () {
    test('Password hashing produces consistent SHA256 hashes with same salt', () {
      const password = 'mySecretPassword123';
      const salt = 'randomSalt_12345';

      final hash1 = DatabaseHelper.hashPassword(password, salt);
      final hash2 = DatabaseHelper.hashPassword(password, salt);

      expect(hash1, isNotEmpty);
      expect(hash1, equals(hash2));
    });

    test('Different salts produce different hashes for same password', () {
      const password = 'mySecretPassword123';
      final salt1 = DatabaseHelper.generateSalt();
      final salt2 = DatabaseHelper.generateSalt();

      final hash1 = DatabaseHelper.hashPassword(password, salt1);
      final hash2 = DatabaseHelper.hashPassword(password, salt2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('Salt generator creates unique, non-empty base64 strings', () {
      final saltA = DatabaseHelper.generateSalt();
      final saltB = DatabaseHelper.generateSalt();

      expect(saltA, isNotEmpty);
      expect(saltB, isNotEmpty);
      expect(saltA, isNot(equals(saltB)));
    });

    test('User model serializes to and from Map', () {
      final user = User(
        id: 7,
        username: 'alice',
        passwordHash: 'hashvalue',
        salt: 'saltvalue',
        createdAt: '2026-11-17T12:00:00Z',
      );

      final map = user.toMap();
      expect(map['id'], 7);
      expect(map['username'], 'alice');
      expect(map['password_hash'], 'hashvalue');
      expect(map['salt'], 'saltvalue');

      final reconstructed = User.fromMap(map);
      expect(reconstructed.id, 7);
      expect(reconstructed.username, 'alice');
      expect(reconstructed.passwordHash, 'hashvalue');
      expect(reconstructed.salt, 'saltvalue');
    });

    test('Username validation rules', () {
      // Validator logic used in Login and Register forms
      String? validateUsername(String? val) {
        if (val == null || val.trim().isEmpty) return 'Username cannot be empty';
        if (val.trim().length < 3) return 'Username must be at least 3 characters';
        return null;
      }

      expect(validateUsername(''), isNotNull);
      expect(validateUsername('  '), isNotNull);
      expect(validateUsername('ab'), isNotNull);
      expect(validateUsername('abc'), isNull);
      expect(validateUsername('valid_user'), isNull);
    });

    test('Password validation rules', () {
      String? validatePassword(String? val) {
        if (val == null || val.isEmpty) return 'Password cannot be empty';
        if (val.length < 4) return 'Password must be at least 4 characters';
        return null;
      }

      expect(validatePassword(''), isNotNull);
      expect(validatePassword('123'), isNotNull);
      expect(validatePassword('1234'), isNull);
      expect(validatePassword('securePass!'), isNull);
    });
  });
}
