import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/attendance_page/AttendancePage.dart';
import 'package:kliktoko/camera_page/CameraPage.dart';
import 'package:kliktoko/home_page/Homepage/HomePage.dart';
import 'package:kliktoko/gudang_page/GudangPage/GudangPage.dart';
import 'package:kliktoko/profile_page/ProfilePage/ProfilePage.dart';
import 'package:kliktoko/gudang_page/GudangControllers/GudangController.dart';
import 'package:kliktoko/ReusablePage/detailPage.dart';
import 'package:kliktoko/theme/app_theme.dart';

class NavController extends GetxController {
  static NavController get to => Get.find();
  final _selectedIndex = 0.obs;

  // Define the main pages for the navigation bar
  final List<Widget> pages = [
    HomePage(key: ValueKey("HomePage")),
    const GudangPage(key: ValueKey("GudangPage")),
    Container(
        key: ValueKey("PlaceholderPage")), // Placeholder for camera button
    const AttendancePage(key: ValueKey("AttendancePage")),
    ProfilePage(key: ValueKey("ProfilePage")),
  ];

  int get selectedIndex => _selectedIndex.value;
  set selectedIndex(int value) => _selectedIndex.value = value;

  void changePage(int index) {
    // If it's the camera button (index 2)
    if (index == 2) {
      openQRScanner();
    }
    // Otherwise, change to the selected page
    else if (_selectedIndex.value != index) {
      _selectedIndex.value = index;
    }
  }

  // Method to open the QR scanner
  Future<void> openQRScanner() async {
    try {
      // Navigate to the camera page and wait for result
      final CameraPage cameraPage = const CameraPage();
      final result = await Get.to(() => cameraPage);

      // Process the scanned code if we have a result
      if (result != null) {
        // Immediately process the scanned code (BEFORE showing the detail page)
        await processScannedCode(result);
      }
    } catch (e) {
      print('Error opening camera: $e');
      Get.snackbar(
        'Error',
        'Failed to open camera. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.black,
      );
    }
  }

  // Process the scanned QR code with improved product lookup
  Future<void> processScannedCode(String code) async {
    print('Scanned QR code: $code');

    // First try to look up the product by code
    if (Get.isRegistered<GudangController>()) {
      final gudangController = Get.find<GudangController>();
      final product = gudangController.findProductByCode(code);

      if (product != null) {
        // Found a matching product - navigate to product detail page
        // Use Get.off instead of Get.to to prevent going back to camera
        await Get.off(() => ProductDetailPage(product: product));
        return;
      }
    }

    // If no product was found, just show the scanned code
    Get.snackbar(
      'Code Scanned',
      'Scanned code: $code',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.successColor,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
      mainButton: TextButton(
        onPressed: () {
          // Navigate to inventory page to search for the code
          _selectedIndex.value = 1; // Switch to GudangPage
          if (Get.isRegistered<GudangController>()) {
            final gudangController = Get.find<GudangController>();
            gudangController
                .updateSearchQuery(code); // Apply search filter with code
          }
        },
        child: Text(
          'Search',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // This method is kept for backward compatibility but redirects to the QR scanner
  void handleAddButton() {
    openQRScanner();
  }
}
