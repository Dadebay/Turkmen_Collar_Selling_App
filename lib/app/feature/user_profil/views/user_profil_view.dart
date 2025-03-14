import 'package:get/get.dart';
import 'package:yaka2/app/product/buttons/profile_button.dart';

import '../../../product/constants/index.dart';
import '../controllers/user_profil_controller.dart';

class UserProfilView extends StatefulWidget {
  const UserProfilView({super.key});

  @override
  State<UserProfilView> createState() => _UserProfilViewState();
}

class _UserProfilViewState extends State<UserProfilView> {
  final UserProfilController userProfilController = Get.put(UserProfilController());

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: ListConstants.profilePageIcons.length,
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return ListConstants.profilePageIcons[index]['showOnLogin'] && !userProfilController.userLogin.value
            ? SizedBox.shrink()
            : ListConstants.profilePageIcons[index]['name'] == 'signUp' && userProfilController.userLogin.value
                ? SizedBox.shrink()
                : ProfilButton(
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
