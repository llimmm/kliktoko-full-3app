import 'package:get/get.dart';
import 'package:kliktoko/login_page/Loginpage/LoginBottomSheet.dart';
import '../storage/storage_service.dart';
import 'package:flutter/material.dart';

class SplashController extends GetxController {
  final StorageService _storageService = StorageService();
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      await _storageService.init();
      await Future.delayed(const Duration(seconds: 2));

      final token = await _storageService.getToken();
      final isLoggedIn = await _storageService.isLoggedIn();

      print('Token status: ${token != null ? 'exists' : 'null'}');
      print('Login status: $isLoggedIn');

      if (isLoggedIn && token != null && token.isNotEmpty) {
        print('Navigating to bottom navigation');
        await Get.offAllNamed(
            '/bottomnav'); // Changed to lowercase to match route name
      } else {
        print('Invalid login state detected, clearing data');
        await _storageService.clearLoginData(); // Clear any invalid login state
        Get.bottomSheet(
          const LoginBottomSheet(),
          isDismissible: true,
          enableDrag: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        );
      }
    } catch (e) {
      print('Error checking login status: $e');
      await _storageService.clearLoginData();
      Get.bottomSheet(
        const LoginBottomSheet(),
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
