import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/login_page/LoginController/LoginController.dart';
import 'package:kliktoko/login_page/Loginpage/LoginBottomSheet.dart';
import 'package:kliktoko/storage/storage_service.dart';

// Utility class to manage login bottom sheet display
class LoginSheetUtils {
  // Singleton pattern
  static final LoginSheetUtils _instance = LoginSheetUtils._internal();
  factory LoginSheetUtils() => _instance;
  LoginSheetUtils._internal();

  // Flag to prevent multiple bottom sheets
  bool _isBottomSheetShowing = false;
  final StorageService _storageService = StorageService();

  // Check if user is logged in before showing login sheet
  Future<bool> checkLoginStatus() async {
    try {
      await _storageService.init();
      return await _storageService.verifyLoginState();
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Method to show login bottom sheet with safeguards
  Future<void> showLoginBottomSheet(BuildContext context) async {
    // Prevent multiple sheets from appearing
    if (_isBottomSheetShowing) return;
    _isBottomSheetShowing = true;

    // Check if user is already logged in
    final isLoggedIn = await checkLoginStatus();
    if (isLoggedIn) {
      print('User is already logged in, navigating to home');
      _isBottomSheetShowing = false;
      Get.offAllNamed('/bottomnav');
      return;
    }

    // Register the controller first before showing the sheet
    if (!Get.isRegistered<LoginController>()) {
      Get.put(LoginController());
    }

    // Show the bottom sheet with improved keyboard handling
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important for keyboard handling
      backgroundColor: Colors.transparent,
      // Enable sheet to resize when keyboard appears
      builder: (context) => const LoginBottomSheet(),
    ).then((_) {
      // Reset the flag after sheet is closed with a delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _isBottomSheetShowing = false;
      });
    });
  }
}