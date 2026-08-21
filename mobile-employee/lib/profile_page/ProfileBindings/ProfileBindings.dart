import 'package:get/get.dart';
import 'package:kliktoko/profile_page/ProfileController/ProfileController.dart';

class ProfileBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
