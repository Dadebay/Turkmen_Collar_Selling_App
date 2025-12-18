import 'package:get/get.dart';
import 'package:yaka2/app/feature/payment/controllers/payment_status_controller.dart';
import 'package:yaka2/app/feature/user_profil/components/profile_button.dart';

import '../../../product/constants/index.dart';
import '../controllers/user_profil_controller.dart';

class UserProfilView extends StatefulWidget {
  const UserProfilView({super.key});

  @override
  State<UserProfilView> createState() => _UserProfilViewState();
}

class _UserProfilViewState extends State<UserProfilView> {
  final UserProfilController userProfilController = Get.put(UserProfilController());
  final PaymentStatusController paymentStatusController = Get.find();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: ListConstants.profilePageIcons.length,
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        // Hide items based on login status
        if (ListConstants.profilePageIcons[index]['showOnLogin'] && !userProfilController.userLogin.value) {
          return SizedBox.shrink();
        }

        // Hide signUp if user is logged in
        if (ListConstants.profilePageIcons[index]['name'] == 'signUp' && userProfilController.userLogin.value) {
          return SizedBox.shrink();
        }

        // Hide addMoney if payment is disabled
        if (ListConstants.profilePageIcons[index]['name'] == 'addMoney' && paymentStatusController.isPaymentDisabled.value) {
          return SizedBox.shrink();
        }
        if (ListConstants.profilePageIcons[index]['name'] == 'open_folder' && paymentStatusController.isPaymentDisabled.value) {
          return SizedBox.shrink();
        }
        return ProfilButton(
          name: ListConstants.profilePageIcons[index]['name'],
          icon: ListConstants.profilePageIcons[index]['icon'],
          onTap: ListConstants.profilePageIcons[index]['onTap'],
          langIcon: ListConstants.profilePageIcons[index]['langIcon'],
          langIconStatus: ListConstants.profilePageIcons[index]['langIconsStatus'],
        );
      },
    );
  }
}
