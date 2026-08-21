import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kliktoko/attendance_page/SharedAttendanceController.dart';
import 'package:kliktoko/home_page/HomeBindings/HomeBindings.dart';
import 'package:kliktoko/home_page/HomeController/HomeController.dart';
import 'package:kliktoko/home_page/HomePage/HomePage.dart';
import 'package:kliktoko/login_page/LoginBindings/LoginBindings.dart';
import 'package:kliktoko/login_page/Loginpage/LoginBottomSheet.dart';
import 'package:kliktoko/navigation/BottomNavBar.dart';
import 'package:kliktoko/navigation/NavBindings.dart';
import 'package:kliktoko/start.dart';
import 'package:kliktoko/storage/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Initialize storage service and SharedAttendanceController
  final storageService = Get.put(StorageService());
  await storageService.init();
  Get.put(SharedAttendanceController(), permanent: true); // Add this line
  Get.put(HomeController(), permanent: true); // Add this line

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simoto Employee',
      theme: AppTheme.lightTheme,
      initialRoute:
          '/', // Changed from '/start' to '/' to match the route definition
      getPages: [
        GetPage(
          name: '/',
          page: () => const StartPage(),
          binding: BindingsBuilder(() {
            Get.put(StorageService());
          }),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/login',
          page: () => const Material(
            child: Scaffold(
              body: LoginBottomSheet(),
            ),
          ),
          binding: LoginBinding(),
          transition: Transition.fadeIn,
          preventDuplicates: false, // Allow re-opening login if needed
        ),
        GetPage(
          name: '/home',
          page: () => const HomePage(),
          binding: HomeBindings(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/bottomnav',
          page: () => const FloatingBottomNavBar(),
          binding: NavBindings(),
          transition: Transition.fadeIn,
        ),
      ],
    );
  }
}
