import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'NavController.dart';
import '../theme/app_theme.dart';

class FloatingBottomNavBar extends StatelessWidget {
  const FloatingBottomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize or find the navigation controller
    NavController controller;
    try {
      controller = Get.find<NavController>();
    } catch (e) {
      controller = Get.put(NavController(), permanent: true);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Navigation bar dimensions - responsive to screen
    final navBarWidth = screenWidth * 0.85;
    final navBarHeight = 70.0;
    final safeBottomPadding = bottomPadding > 0 ? bottomPadding + 15.0 : 25.0;

    return Scaffold(
      // Light purple background as shown in the reference image
      backgroundColor: AppTheme.lightPurpleBackground,

      // Use resizeToAvoidBottomInset: false to prevent resizing when keyboard appears
      resizeToAvoidBottomInset: false,

      body: Stack(
        children: [
          // Main content area - displays the selected page
          Obx(() => IndexedStack(
                index: controller.selectedIndex,
                children: controller.pages,
              )),

          // Floating navigation bar - now attached to a SafeArea
          Positioned(
            bottom: safeBottomPadding,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Custom shaped navigation bar with precise notch
                  CustomPaint(
                    size: Size(navBarWidth, navBarHeight),
                    painter: NavBarPainter(
                      color: AppTheme.darkCardBackground,
                    ),
                  ),

                  // Navigation buttons - positioned top-center
                  SizedBox(
                    width: navBarWidth,
                    height: navBarHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Home button
                          _buildNavButton(
                            index: 0,
                            controller: controller,
                            isActive: true,
                            icon: _buildHomeIcon,
                          ),

                          // Inventory button
                          _buildNavButton(
                            index: 1,
                            controller: controller,
                            isActive: true,
                            icon: _buildInventoryIcon,
                          ),

                          // Empty space for the QR scanner button
                          const SizedBox(width: 60),

                          // Calendar button
                          _buildNavButton(
                            index: 3,
                            controller: controller,
                            isActive: true,
                            icon: _buildAttendanceIcon,
                          ),

                          // Profile button
                          _buildNavButton(
                            index: 4,
                            controller: controller,
                            isActive: true,
                            icon: _buildProfileIcon,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center floating QR scanner button
                  Positioned(
                    top: -27.0,
                    child: GestureDetector(
                      onTap: () => controller
                          .openQRScanner(), // Direct call to open QR scanner
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 54.0,
                        height: 54.0,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KtColor.black,
                            width: 2.0,
                          ),
                          // Bayangan geser keras, bukan glow lembut.
                          boxShadow: KtBrutal.shadow,
                        ),
                        // Inner container to create the double ring effect
                        child: Container(
                          margin: const EdgeInsets.all(2.0),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: KtColor.black,
                              width: 2.0,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.qr_code_scanner_sharp,
                              // Putih di atas ungu = 5,70:1; primaryText gelap
                              // hanya 3,11:1.
                              color: Colors.white,
                              size: 28.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Button builder for navigation items
  Widget _buildNavButton({
    required int index,
    required NavController controller,
    required bool isActive,
    required Widget Function(bool isSelected, bool isActive) icon,
  }) {
    return Obx(() {
      final isSelected = controller.selectedIndex == index;
      final buttonSize = 50.0;

      return GestureDetector(
        onTap: () => controller.changePage(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          // Tab aktif = isian ungu; nonaktif = abu gelap yang melebur ke pill.
          // Tanpa bayangan lembut — tombol di dalam bar tidak mengambang.
          decoration: BoxDecoration(
            color:
                isSelected ? AppTheme.primaryPurple : const Color(0xFF303030),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: icon(isSelected, isActive),
          ),
        ),
      );
    });
  }

  // Home icon implementation
  Widget _buildHomeIcon(bool isSelected, bool isActive) {
    if (!isActive) return const SizedBox();

    return Icon(
      Icons.home,
      // Putih di tab aktif maupun nonaktif: yang aktif ditandai isian ungu,
      // bukan warna ikon. Ikon gelap di atas ungu hanya 3,11:1; putih 5,70:1.
      color: Colors.white,
      size: 28.0,
    );
  }

  // Inventory/box icon implementation
  Widget _buildInventoryIcon(bool isSelected, bool isActive) {
    if (!isActive) return const SizedBox();

    return Icon(
      Icons.inventory_2_outlined,
      // Putih di tab aktif maupun nonaktif: yang aktif ditandai isian ungu,
      // bukan warna ikon. Ikon gelap di atas ungu hanya 3,11:1; putih 5,70:1.
      color: Colors.white,
      size: 28.0,
    );
  }

  // Calendar icon implementation
  Widget _buildAttendanceIcon(bool isSelected, bool isActive) {
    if (!isActive) return const SizedBox();

    return Icon(
      Icons.calendar_month_outlined,
      // Putih di tab aktif maupun nonaktif: yang aktif ditandai isian ungu,
      // bukan warna ikon. Ikon gelap di atas ungu hanya 3,11:1; putih 5,70:1.
      color: Colors.white,
      size: 30.0,
    );
  }

  // Profile icon implementation
  Widget _buildProfileIcon(bool isSelected, bool isActive) {
    if (!isActive) return const SizedBox();

    return Icon(
      Icons.person_outline,
      // Putih di tab aktif maupun nonaktif: yang aktif ditandai isian ungu,
      // bukan warna ikon. Ikon gelap di atas ungu hanya 3,11:1; putih 5,70:1.
      color: Colors.white,
      size: 28.0,
    );
  }
}

// Custom painter for drawing the navigation bar with a notch for the add button
class NavBarPainter extends CustomPainter {
  final Color color;

  NavBarPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double cornerRadius = 35.0;

    // Create path for the navigation bar with exact notch shape
    final path = Path();

    // Start from the top-left with rounded corner
    path.moveTo(cornerRadius, 0);

    // Draw top edge to notch start
    path.lineTo(size.width / 2 - 33, 0); // Slightly wider notch

    // Draw precise notch curve - exactly as shown in the reference
    path.arcToPoint(
      Offset(size.width / 2 + 33, 0), // Slightly wider notch
      radius: const Radius.circular(33), // Slightly wider notch
      clockwise: false,
    );

    // Draw top edge from notch to top-right corner
    path.lineTo(size.width - cornerRadius, 0);

    // Draw top-right rounded corner
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Draw right edge
    path.lineTo(size.width, size.height - cornerRadius);

    // Draw bottom-right rounded corner
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Draw bottom edge
    path.lineTo(cornerRadius, size.height);

    // Draw bottom-left rounded corner
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Draw left edge
    path.lineTo(0, cornerRadius);

    // Draw top-left rounded corner
    path.arcToPoint(
      Offset(cornerRadius, 0),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Close the path
    path.close();

    // Neobrutalism: bayangan geser tanpa blur (salinan path yang sama, digeser
    // 4px, berisi hitam pekat), lalu isian, lalu border hitam 3px. Menggantikan
    // drawShadow lembut yang membuat pill mengambang tanpa tepi tegas.
    final shadowPaint = Paint()
      ..color = KtColor.black
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      path.shift(KtBrutal.shadowOffset),
      shadowPaint,
    );

    // Draw the navigation bar
    canvas.drawPath(path, paint);

    // Border hitam tegas mengelilingi pill dan takiknya.
    final borderPaint = Paint()
      ..color = KtColor.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = KtBrutal.borderWidth;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
