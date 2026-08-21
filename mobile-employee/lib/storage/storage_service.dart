import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      try {
        _prefs = await SharedPreferences.getInstance();
        _isInitialized = true;
        print('StorageService initialized successfully');
      } catch (e) {
        print('Error initializing StorageService: $e');
        throw Exception('Failed to initialize storage: $e');
      }
    }
  }

  Future<void> saveToken(String token) async {
    await init();
    try {
      final result = await _prefs.setString(tokenKey, token);
      final loginResult = await _prefs.setBool(isLoggedInKey, true);
      
      if (!result || !loginResult) {
        throw Exception('Failed to save token to SharedPreferences');
      }
      
      print('Token saved: ${token.substring(0, math.min(token.length, 10))}...');
    } catch (e) {
      print('Error saving token: $e');
      throw Exception('Failed to save token: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    await init();
    return _prefs.getBool(isLoggedInKey) ?? false;
  }

  Future<String?> getToken() async {
    await init();
    try {
      final token = _prefs.getString(tokenKey);
      if (token != null && token.isNotEmpty) {
        print('Retrieved token: ${token.substring(0, math.min(token.length, 10))}...');
      } else {
        print('No token found in storage');
      }
      return token;
    } catch (e) {
      print('Error retrieving token: $e');
      return null;
    }
  }

  Future<void> clearAllUserData() async {
    await init();

    // First clear specific keys for user data and authentication
    final keysToRemove = [tokenKey, userDataKey, isLoggedInKey];

    print('Starting to clear all user data...');
    for (var key in keysToRemove) {
      if (_prefs.containsKey(key)) {
        await _prefs.remove(key);
        print('Removed key: $key');
      }
    }

    // Set logged in status explicitly to false for clarity
    await _prefs.setBool(isLoggedInKey, false);

    // Get all keys to check if there are any additional user-related data
    final allKeys = _prefs.getKeys();
    print('Remaining keys in storage: ${allKeys.length}');

    print('All user data cleared successfully');
  }

  // This method is now just a wrapper for clearAllUserData() for backwards compatibility
  Future<void> clearLoginData() async {
    await clearAllUserData();
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await init();
    try {
      final jsonData = json.encode(userData);
      final result = await _prefs.setString(userDataKey, jsonData);
      
      if (!result) {
        throw Exception('Failed to save user data to SharedPreferences');
      }
      
      print('User data saved successfully: $userData');
    } catch (e) {
      print('Error saving user data: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    await init();
    try {
      final String? userDataString = _prefs.getString(userDataKey);
      if (userDataString != null && userDataString.isNotEmpty) {
        try {
          final data = json.decode(userDataString) as Map<String, dynamic>;
          print('Retrieved user data: $data');
          return data;
        } catch (e) {
          print('Error parsing user data: $e');
          // Try to recover corrupted data
          await _prefs.remove(userDataKey);
          return null;
        }
      } else {
        print('No user data found in storage');
        return null;
      }
    } catch (e) {
      print('Error retrieving user data: $e');
      return null;
    }
  }

  Future<bool> verifyLoginState() async {
    try {
      await init();
      final token = await getToken();
      final userData = await getUserData();
      final isLoggedIn = await this.isLoggedIn();
      
      print('== STORAGE STATE VERIFICATION ==');
      print('Token exists: ${token != null && token.isNotEmpty}');
      print('User data exists: ${userData != null}');
      print('isLoggedIn flag: $isLoggedIn');
      
      // Consider logged in if we have both token and user data
      return token != null && token.isNotEmpty && userData != null && isLoggedIn;
    } catch (e) {
      print('Error verifying login state: $e');
      return false;
    }
  }
}