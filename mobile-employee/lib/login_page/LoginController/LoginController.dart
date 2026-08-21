import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/login_page/LoginService/LoginService.dart';
import 'package:kliktoko/storage/storage_service.dart';

class LoginController extends GetxController {
  final LoginService _loginService = LoginService();
  final StorageService _storageService = StorageService();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isPasswordVisible = false.obs; // For password visibility toggle

  @override
  void onInit() {
    super.onInit();
    // Initialize storage service early and check for existing login
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    try {
      await _storageService.init();
      final isAlreadyLoggedIn = await _storageService.verifyLoginState();

      if (isAlreadyLoggedIn) {
        print('User is already logged in, navigating to home');
        // Optional: Add a slight delay to ensure the UI is ready
        await Future.delayed(const Duration(milliseconds: 100));
        Get.offAllNamed('/bottomnav');
      }
    } catch (e) {
      print('Error initializing storage: $e');
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  void login() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      errorMessage.value = 'Silakan masukkan username dan password';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    print('Starting login process for user: ${usernameController.text}');

    try {
      // Ensure storage service is initialized first
      await _storageService.init();

      final response = await _loginService.login(
        usernameController.text,
        passwordController.text,
      );

      print('Login response received: success=${response.success}, '
          'token=${response.token.isNotEmpty ? 'Present' : 'Missing'}');

      if (response.success && response.token.isNotEmpty) {
        try {
          // Check user role before proceeding
          if (!_isValidUserRole(response.user)) {
            print('Login blocked: User has invalid role or is inactive');

            // Check if user is inactive
            bool isInactive = false;
            if (response.user.containsKey('is_active')) {
              var isActiveValue = response.user['is_active'];
              if (isActiveValue is bool) {
                isInactive = !isActiveValue;
              } else if (isActiveValue is int) {
                isInactive = isActiveValue == 0;
              } else if (isActiveValue is String) {
                isInactive = isActiveValue.toLowerCase() == 'false' ||
                    isActiveValue == '0';
              }
            }

            if (isInactive) {
              errorMessage.value =
                  'Akun Anda telah dinonaktifkan. Silakan hubungi administrator.';
            } else {
              errorMessage.value =
                  'Akses ditolak. Hanya karyawan yang dapat mengakses aplikasi ini.';
            }

            _clearPasswordField();
            return;
          }

          // Save token first
          await _storageService.saveToken(response.token);
          print('Token saved successfully');

          // Prepare user data with proper fallbacks
          Map<String, dynamic> userData = {};
          if (response.user.isNotEmpty) {
            userData = Map<String, dynamic>.from(response.user);
          } else {
            // If API didn't return user data, create basic data from username
            userData = {'name': usernameController.text};
            print('Created basic user data from username');
          }

          // Ensure username is present
          if (!userData.containsKey('name') ||
              userData['name'] == null ||
              userData['name'].toString().isEmpty) {
            userData['name'] = usernameController.text;
            print('Added missing name field from username');
          }

          print('Saving user data: $userData');
          await _storageService.saveUserData(userData);

          // Verify data was saved
          final loginVerified = await _storageService.verifyLoginState();

          if (loginVerified) {
            print('Login data stored successfully, navigating to home');
            Get.offAllNamed('/bottomnav');
          } else {
            print('Data verification failed after login');
            errorMessage.value =
                'Login berhasil tetapi penyimpanan data gagal. Silakan coba lagi.';
          }
        } catch (e) {
          print('Error saving login data: $e');
          errorMessage.value =
              'Login berhasil tetapi penyimpanan data gagal: $e';
        }
      } else {
        print('Login failed: ${response.message}');
        // Handle different error messages and convert to Indonesian
        String indonesianMessage =
            _convertErrorMessageToIndonesian(response.message);
        errorMessage.value = indonesianMessage;
        // Clear password field when login fails
        _clearPasswordField();
      }
    } catch (e) {
      print('Login error: $e');
      String indonesianMessage = _convertErrorMessageToIndonesian(e.toString());
      errorMessage.value = indonesianMessage;
      // Clear password field when login fails
      _clearPasswordField();
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to clear password field
  void _clearPasswordField() {
    passwordController.clear();
    // Also hide password visibility when clearing
    isPasswordVisible.value = false;
  }

  // Helper method to validate user role
  bool _isValidUserRole(Map<String, dynamic> userData) {
    // Check if user data is empty
    if (userData.isEmpty) {
      print('User data is empty, allowing login as fallback');
      return true; // Allow login if no user data (fallback)
    }

    // Check if user is active
    bool isActive = true; // Default to true if not specified
    if (userData.containsKey('is_active')) {
      var isActiveValue = userData['is_active'];
      if (isActiveValue is bool) {
        isActive = isActiveValue;
      } else if (isActiveValue is int) {
        isActive = isActiveValue == 1;
      } else if (isActiveValue is String) {
        isActive =
            isActiveValue.toLowerCase() == 'true' || isActiveValue == '1';
      }
    }

    print('User active status: $isActive');

    // Block inactive users
    if (!isActive) {
      print('User is inactive - access denied');
      return false;
    }

    // Get role from user data - check multiple possible field names
    String? role = userData['role']?.toString().toLowerCase() ??
        userData['user_role']?.toString().toLowerCase() ??
        userData['type']?.toString().toLowerCase() ??
        userData['user_type']?.toString().toLowerCase() ??
        '';

    print('User role detected: $role');

    // Only allow 'karyawan' role
    if (role == 'karyawan' || role == 'employee') {
      print('User role is valid (karyawan)');
      return true;
    }

    // Block admin and other roles
    if (role == 'admin' || role == 'administrator') {
      print('User role is admin - access denied');
      return false;
    }

    // If role is empty or unknown, allow login as fallback
    if (role.isEmpty) {
      print('User role is empty, allowing login as fallback');
      return true;
    }

    // Block any other roles that are not 'karyawan'
    print('User role is not karyawan: $role - access denied');
    return false;
  }

  // Public wrapper to allow testing and external validation without exposing internals
  bool isValidUserRole(Map<String, dynamic> userData) {
    return _isValidUserRole(userData);
  }

  // Helper method to convert English error messages to Indonesian
  String _convertErrorMessageToIndonesian(String errorMessage) {
    if (errorMessage.isEmpty) {
      return 'Login gagal. Silakan periksa username dan password Anda.';
    }

    // Convert common English error messages to Indonesian
    if (errorMessage.contains('401') || errorMessage.contains('Unauthorized')) {
      return 'Login gagal. Username atau password salah.';
    }

    if (errorMessage.contains('404') || errorMessage.contains('Not Found')) {
      return 'Login gagal. Username tidak ditemukan.';
    }

    if (errorMessage.contains('500') ||
        errorMessage.contains('Internal Server Error')) {
      return 'Login gagal. Terjadi kesalahan pada server. Silakan coba lagi nanti.';
    }

    if (errorMessage.contains('Network') ||
        errorMessage.contains('Connection')) {
      return 'Login gagal. Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }

    if (errorMessage.contains('Request failed with status')) {
      return 'Login gagal. Username atau password salah.';
    }

    if (errorMessage.contains('Login failed')) {
      return 'Login gagal. Silakan periksa kredensial Anda.';
    }

    // Check for inactive account error messages
    if (errorMessage.contains('inactive') ||
        errorMessage.contains('disabled') ||
        errorMessage.contains('deactivated') ||
        errorMessage.contains('is_active') ||
        errorMessage.contains('account disabled')) {
      return 'Akun Anda telah dinonaktifkan. Silakan hubungi administrator.';
    }

    // Check for role-related error messages
    if (errorMessage.contains('role') || errorMessage.contains('Role')) {
      return 'Akses ditolak. Hanya karyawan yang dapat mengakses aplikasi ini.';
    }

    // For any other error messages, provide a generic Indonesian message
    return 'Login gagal. Silakan periksa username dan password Anda.';
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
