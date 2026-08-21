import 'package:get/get.dart';
import 'package:kliktoko/home_page/HomeController/HomeController.dart';
import 'package:kliktoko/gudang_page/GudangControllers/GudangController.dart';

// GudangBindings class to initialize the controllers
class GudangBindings extends Bindings {
  @override
  void dependencies() {
    // Register HomeController globally
    Get.put<HomeController>(HomeController(), permanent: true);

    // Lazily load GudangController to initialize it when needed
    Get.lazyPut<GudangController>(() => GudangController());
    
    // You can also use Get.put() if you want it to be initialized immediately
    // Get.put<GudangController>(GudangController(), permanent: true); // Uncomment if needed
  }
}
