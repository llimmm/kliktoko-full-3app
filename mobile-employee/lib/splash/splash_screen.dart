import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'splash_controller.dart';
import '../start.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashController controller = Get.put(SplashController());

  @override
  void initState() {
    super.initState();
    controller.checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    // No specific responsive changes needed here since it's just a stack with the StartPage
    // and a centered loading indicator, which are already responsive by default
    return Stack(
      children: [
        const StartPage(),
        Obx(() => controller.isLoading.value
            ? Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const CircularProgressIndicator(),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }
}
