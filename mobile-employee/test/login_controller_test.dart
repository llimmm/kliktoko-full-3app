import 'package:flutter_test/flutter_test.dart';
import 'package:kliktoko/login_page/LoginController/LoginController.dart';

void main() {
  group('LoginController Role Validation Tests', () {
    late LoginController controller;

    setUp(() {
      controller = LoginController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('should allow login for karyawan role', () {
      Map<String, dynamic> userData = {
        'name': 'John Doe',
        'role': 'karyawan',
        'email': 'john@example.com'
      };

      bool isValid = controller.isValidUserRole(userData);
      expect(isValid, true);
    });

    test('should allow login for employee role (English)', () {
      Map<String, dynamic> userData = {
        'name': 'Jane Doe',
        'role': 'employee',
        'email': 'jane@example.com'
      };

      bool isValid = controller.isValidUserRole(userData);
      expect(isValid, true);
    });

    test('should block login for admin role', () {
      Map<String, dynamic> userData = {
        'name': 'Admin User',
        'role': 'admin',
        'email': 'admin@example.com'
      };

      bool isValid = controller.isValidUserRole(userData);
      expect(isValid, false);
    });

    test('should block login for administrator role', () {
      Map<String, dynamic> userData = {
        'name': 'Admin User',
        'role': 'administrator',
        'email': 'admin@example.com'
      };

      bool isValid = controller.isValidUserRole(userData);
      expect(isValid, false);
    });

    test('should allow login when role is empty (fallback)', () {
      Map<String, dynamic> userData = {
        'name': 'Unknown User',
        'email': 'unknown@example.com'
      };

      bool isValid = controller.isValidUserRole(userData);
      expect(isValid, true);
    });

    test('should allow login when user data is empty (fallback)', () {
      Map<String, dynamic> userData = {};

      bool isValid = controller.isValidUserRole(userData);
      expect(isValid, true);
    });

    test('should check multiple role field names', () {
      // Test user_role field
      Map<String, dynamic> userData1 = {
        'name': 'User 1',
        'user_role': 'karyawan'
      };
      expect(controller.isValidUserRole(userData1), true);

      // Test type field
      Map<String, dynamic> userData2 = {'name': 'User 2', 'type': 'karyawan'};
      expect(controller.isValidUserRole(userData2), true);

      // Test user_type field
      Map<String, dynamic> userData3 = {
        'name': 'User 3',
        'user_type': 'karyawan'
      };
      expect(controller.isValidUserRole(userData3), true);
    });

    test('should block other roles that are not karyawan', () {
      Map<String, dynamic> userData = {
        'name': 'Manager User',
        'role': 'manager',
        'email': 'manager@example.com'
      };

      bool isValid = controller.isValidUserRole(userData);
      expect(isValid, false);
    });

    test('should handle case insensitive role checking', () {
      Map<String, dynamic> userData = {
        'name': 'User',
        'role': 'KARYAWAN', // uppercase
        'email': 'user@example.com'
      };

      bool isValid = controller.isValidUserRole(userData);
      expect(isValid, true);
    });
  });
}
