import 'package:flutter/foundation.dart';
import '../service/api_service.dart';

class AuthController with ChangeNotifier {
  final ApiService apiService;
  AuthController({required this.apiService}) {
    // Initialize auth state on creation
    _initAuthState();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool get isLoggedIn => apiService.token != null;

  // Initialize auth state by loading saved token and validating it
  Future<void> _initAuthState() async {
    if (kDebugMode) {
      print('AuthController: Initializing auth state');
    }

    // Token is loaded automatically by ApiService constructor
    if (isLoggedIn) {
      if (kDebugMode) {
        print('AuthController: Found saved token, validating...');
      }

      // Perform a lightweight validation if needed
      // This is optional - the token will be validated on API calls
      _validateSavedToken();
    } else {
      if (kDebugMode) {
        print('AuthController: No saved token found, user needs to login');
      }
    }
  }

  // Validate the saved token with a lightweight request
  Future<void> _validateSavedToken() async {
    try {
      // Only do a validation call if we have a token
      if (!isLoggedIn) return;

      final isValid = await validateToken();

      if (!isValid) {
        if (kDebugMode) {
          print('AuthController: Saved token is invalid, logging out');
        }
        // Clear invalid token
        await logout();
      } else if (kDebugMode) {
        print('AuthController: Saved token is valid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthController: Error validating token: $e');
      }
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null; // Reset error setiap kali login
    notifyListeners();

    if (kDebugMode) {
      print('AuthController: Attempting login with username $username');
    }

    try {
      await apiService.login(username, password);
      _error = null;

      if (kDebugMode) {
        print(
            'AuthController: Login successful, token: ${apiService.token != null ? 'available' : 'null'}');
      }
    } catch (e) {
      // Extract the actual error message from the Exception
      final errorMessage = e.toString();
      // Remove "Exception: " prefix from error message if it exists
      _error = errorMessage.startsWith('Exception: ')
          ? errorMessage.substring('Exception: '.length)
          : errorMessage;

      if (kDebugMode) {
        print('AuthController: Login failed with error: $_error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiService.logout();
      _error = null;
      if (kDebugMode) {
        print('AuthController: Logout successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check token validity - berguna untuk memastikan token masih valid
  Future<bool> validateToken() async {
    if (apiService.token == null) {
      return false;
    }

    try {
      // Coba ambil produk untuk memvalidasi token
      await apiService.getProductsByCategory('any');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Token validation failed: $e');
      }
      return false;
    }
  }
}
