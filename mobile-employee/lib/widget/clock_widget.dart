import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home_page/HomeController/HomeController.dart';
import '../theme/app_theme.dart';

class ClockWidget extends StatelessWidget {
  const ClockWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the controller
    final controller = Get.find<HomeController>();
    
    return Obx(() => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Current time (HH:MM:SS)
        Text(
          controller.getCurrentTime(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 40,
            color: AppTheme.primaryText,
          ),
        ),
        const SizedBox(height: 4),
        // Current date (Day, Date Month Year)
        Text(
          controller.getCurrentDate(),
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ));
  }
}