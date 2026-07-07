import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab2_jta/models/user.dart';
import 'package:prm393_lab2_jta/models/role.dart';
import 'package:prm393_lab2_jta/models/api_error.dart';

void main() {
  group('User Model', () {
    test('fromJson parses camelCase fields', () {
      final json = {
        'userId': 'user123',
        'firebaseUid': 'fb-uid-abc',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'roleId': 'Researcher',
        'roleName': 'Researcher',
      };

      final user = User.fromJson(json);

      expect(user.userId, 'user123');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'Test User');
      expect(user.roleId, 'Researcher');
    });

    test('fromJson handles snake_case fields', () {
      final json = {
        'user_id': 'user456',
        'firebase_uid': 'fb-uid-xyz',
        'email': 'snake@example.com',
        'full_name': 'Snake User',
        'role_id': 'Admin',
        'role_name': 'Admin',
      };

      final user = User.fromJson(json);

      expect(user.userId, 'user456');
      expect(user.email, 'snake@example.com');
      expect(user.fullName, 'Snake User');
    });

    test('fromJson handles null values gracefully', () {
      final json = <String, dynamic>{};

      final user = User.fromJson(json);

      expect(user.userId, '');
      expect(user.email, '');
      expect(user.fullName, '');
    });
  });

  group('Role Model', () {
    test('fromJson parses role fields', () {
      final json = {
        'roleId': 'Customer',
        'roleName': 'Customer',
        'description': 'Customer role',
      };

      final role = Role.fromJson(json);

      expect(role.roleId, 'Customer');
      expect(role.roleName, 'Customer');
      expect(role.description, 'Customer role');
    });

    test('fromJson handles null description', () {
      final json = {
        'roleId': 'Researcher',
        'roleName': 'Researcher',
      };

      final role = Role.fromJson(json);

      expect(role.roleId, 'Researcher');
      expect(role.description, isNull);
    });
  });

  group('ApiError Model', () {
    test('toString formats correctly with status code', () {
      const error = ApiError('Not found', statusCode: 404);
      expect(error.toString(), contains('404'));
      expect(error.toString(), contains('Not found'));
    });

    test('toString formats correctly without status code', () {
      const error = ApiError('Network error');
      expect(error.toString(), contains('unknown'));
      expect(error.toString(), contains('Network error'));
    });
  });
}
