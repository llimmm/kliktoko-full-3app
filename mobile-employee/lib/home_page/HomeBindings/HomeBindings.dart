import 'package:get/get.dart';
import 'package:kliktoko/attendance_page/SharedAttendanceController.dart';
import 'package:kliktoko/home_page/HomeController/HomeController.dart';
import 'package:kliktoko/attendance_page/AttendanceController.dart';

class HomeBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize HomeController as permanent to keep it alive throughout the app
    Get.put<HomeController>(HomeController(), permanent: true);
    Get.lazyPut<AttendanceController>(() => AttendanceController());
    Get.put(SharedAttendanceController());
  }
}
