import 'package:get/get.dart';
import 'package:kliktoko/login_page/LoginController/LoginController.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
