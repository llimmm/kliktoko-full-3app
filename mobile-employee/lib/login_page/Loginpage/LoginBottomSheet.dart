import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kliktoko/login_page/LoginController/LoginController.dart';
import 'package:kliktoko/theme/app_theme.dart';
import 'package:kliktoko/theme/kt_components.dart';

class LoginBottomSheet extends GetView<LoginController> {
  const LoginBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get the keyboard height using viewInsets
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Calculate responsive paddings
    final horizontalPadding = screenWidth * 0.05;
    final verticalSpacing = screenHeight * 0.02;

    return Padding(
      // Add padding to account for keyboard height and safe area
      padding: EdgeInsets.only(
          bottom: keyboardHeight,
          top: MediaQuery.of(context).padding.top * 0.5),
      child: Material(
        color: Colors.transparent,
        child: Container(
          // Use dynamic constraints that adapt to content and keyboard
          constraints: BoxConstraints(
            minHeight: screenHeight * 0.45,
            maxHeight:
                keyboardHeight > 0 ? screenHeight * 0.85 : screenHeight * 0.70,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.cardBackground, AppTheme.backgroundColor],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SingleChildScrollView(
            // This enables scrolling when keyboard appears
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  horizontalPadding,
                  horizontalPadding,
                  // Add extra padding at bottom to ensure content is above keyboard
                  horizontalPadding +
                      (keyboardHeight > 0 ? keyboardHeight * 0.2 + 20 : 0)),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Use minimum size
                children: [
                  SizedBox(height: verticalSpacing),
                  // Title text - adjust font size based on screen width
                  Center(
                    child: Text(
                      'Selamat datang kembali!',
                      style: TextStyle(
                        fontSize: screenWidth < 360 ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: verticalSpacing * 0.4),
                  Center(
                    child: Text(
                      'Silahkan log in terlebih dahulu',
                      style: TextStyle(
                        fontSize: screenWidth < 360 ? 14 : 16,
                        color: AppTheme.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: verticalSpacing * 2),

                  // Username field
                  TextField(
                    controller: controller.usernameController,
                    decoration: InputDecoration(
                      hintText: 'Enter Username....',
                      filled: true,
                      fillColor: AppTheme.lightBorderColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding * 0.8,
                        vertical: verticalSpacing * 0.8,
                      ),
                    ),
                  ),
                  SizedBox(height: verticalSpacing),

                  // Password field with toggle visibility
                  Obx(() => TextField(
                        controller: controller.passwordController,
                        obscureText: !controller.isPasswordVisible.value,
                        decoration: InputDecoration(
                          hintText: 'Enter Password....',
                          filled: true,
                          fillColor: AppTheme.lightBorderColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding * 0.8,
                            vertical: verticalSpacing * 0.8,
                          ),
                          // Add suffix icon for password visibility toggle
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppTheme.secondaryText,
                            ),
                            onPressed: () =>
                                controller.togglePasswordVisibility(),
                          ),
                        ),
                      )),

                  // Error message with improved visibility
                  Obx(() => controller.errorMessage.value.isNotEmpty
                      ? Container(
                          margin: EdgeInsets.only(top: verticalSpacing * 0.6),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: AppTheme.errorColor, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller.errorMessage.value,
                                  style: TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink()),
                  SizedBox(height: verticalSpacing * 1.5),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Obx(() => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.login,
                          // Masuk adalah aksi utama, jadi ungu primer — bukan
                          // hitam. Layar ini muncul langsung setelah start
                          // page, dan tombol hitam mematahkan palet di titik
                          // pertama yang dilihat karyawan.
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            disabledBackgroundColor: AppTheme.borderColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(KtRadii.control),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        )),
                  ),
                  // Add extra padding at the bottom for keyboard
                  SizedBox(
                      height:
                          verticalSpacing * 2 + (keyboardHeight > 0 ? 20 : 0)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
