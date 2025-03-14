import 'package:get/get.dart';

import '../controllers/product_profil_controller.dart';

class ProductProfilBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductProfilController>(
      () => ProductProfilController(),
    );
  }
}
