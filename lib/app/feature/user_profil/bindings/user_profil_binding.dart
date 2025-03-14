import 'package:get/get.dart';

import '../controllers/user_profil_controller.dart';

class UserProfilBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserProfilController>(
      () => UserProfilController(),
    );
  }
}
