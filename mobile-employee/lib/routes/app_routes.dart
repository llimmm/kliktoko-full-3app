import 'package:get/get.dart';
import 'package:kliktoko/gudang_page/GudangPage/GudangPage.dart';
import 'package:kliktoko/home_page/Homepage/HomePage.dart';
import 'package:kliktoko/login_page/LoginBindings/LoginBindings.dart';
import 'package:kliktoko/login_page/Loginpage/LoginBottomSheet.dart';
import 'package:kliktoko/navigation/NavBindings.dart';
import 'package:kliktoko/profile_page/ProfilePage/ProfilePage.dart';
import 'package:kliktoko/start.dart';
import 'package:kliktoko/navigation/BottomNavBar.dart';
import 'package:kliktoko/gudang_page/GudangBindings/GudangBindings.dart';
import 'package:kliktoko/home_page/HomeBindings/HomeBindings.dart';
import 'package:kliktoko/profile_page/ProfileBindings/ProfileBindings.dart';

class AppRoutes {
  static const String start = '/start';
  static const String bottomNav = '/bottomnav';
  static const String home = '/home';
  static const String gudang = '/gudang';
  static const String profile = '/profile';

  static final List<GetPage> routes = [
    GetPage(
      name: start,
      page: () => const StartPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: bottomNav,
      page: () => const FloatingBottomNavBar(),
      binding: NavBindings(),
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      binding: HomeBindings(),
    ),
    GetPage(
      name: gudang,
      page: () => const GudangPage(),
      binding: GudangBindings(),
    ),
    GetPage(
      name: '/profile',
      page: () => ProfilePage(),
      binding: ProfileBindings(), // Menghubungkan ProfileBindings ke rute ini
    ),
    GetPage(
      name: '/login',
      page: () => const LoginBottomSheet(),
      binding: LoginBinding(),
    ),
  ];
}
