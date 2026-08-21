import 'package:get/get.dart';
import 'package:kliktoko/navigation/NavController.dart';
import 'package:kliktoko/attendance_page/AttendanceController.dart';

class NavBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(NavController());
    Get.put(AttendanceController()); // Make sure AttendanceController is initialized
  }
}
