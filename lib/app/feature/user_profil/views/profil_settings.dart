// ignore_for_file: always_declare_return_types

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yaka2/app/feature/user_profil/components/phone_number_textfield.dart';
import 'package:yaka2/app/feature/user_profil/models/about_us_model.dart';
import 'package:yaka2/app/feature/user_profil/services/about_us_service.dart';
import 'package:yaka2/app/product/buttons/agree_button.dart';
import 'package:yaka2/app/product/constants/color_constants.dart';
import 'package:yaka2/app/product/custom_widgets/custom_text_field.dart';
import 'package:yaka2/app/product/custom_widgets/widgets.dart';
import 'package:yaka2/app/product/empty_state/empty_state.dart';

import '../../../product/error_state/error_state.dart';
import '../../../product/loadings/loading.dart';

class ProfilSettings extends StatefulWidget {
  const ProfilSettings({Key? key}) : super(key: key);

  @override
  State<ProfilSettings> createState() => _ProfilSettingsState();
}

class _ProfilSettingsState extends State<ProfilSettings> {
  TextEditingController userNameController = TextEditingController();

  FocusNode userNameFocusNode = FocusNode();

  TextEditingController phoneController = TextEditingController();

  FocusNode phoneFocusNode = FocusNode();

  TextEditingController userSurnameController = TextEditingController();

  FocusNode userSurnameFocusNode = FocusNode();

  String balance = '0.0';

  final storage = GetStorage();

  changeData(String? phone, String? balance) {
    phoneController.text = phone!;
    balance = balance;
  }

  @override
  void initState() {
    super.initState();

    changeUserName();
  }

  changeUserName() async {
    if (storage.read('userName') != null) {
      userNameController.text = storage.read('userName') ?? 'Yok';
      userSurnameController.text = storage.read('sureName') ?? 'Yok';
      if (!mounted) {
        return;
      }
      setState(() {});
    } else {
      userNameController.text = 'Yok';
      userSurnameController.text = 'Yok';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorConstants.primaryColor,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(statusBarColor: ColorConstants.primaryColor, statusBarIconBrightness: Brightness.dark),
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            IconlyLight.arrowLeftCircle,
            color: ColorConstants.blackColor,
          ),
        ),
        title: Text(
          'profil'.tr,
          style: const TextStyle(color: ColorConstants.blackColor),
        ),
      ),
      body: FutureBuilder<UserMeModel>(
        future: AboutUsService().getuserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          } else if (snapshot.hasError) {
            return ErrorState(
              onTap: () {
                AboutUsService().getuserData();
              },
            );
          } else if (snapshot.data == null) {
            return EmptyState(name: 'emptyData', type: EmptyStateType.text);
          }
          changeData(
            snapshot.data!.phone!.substring(4, 12),
            '${snapshot.data!.balance}',
          );
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              textpart('signIn1', false),
              CustomTextField(
                labelName: '',
                controller: userNameController,
                focusNode: userNameFocusNode,
                requestfocusNode: phoneFocusNode,
                isNumber: false,
              ),
              textpart('signIn2', false),
              CustomTextField(
                labelName: '',
                controller: userSurnameController,
                focusNode: userSurnameFocusNode,
                requestfocusNode: phoneFocusNode,
                isNumber: false,
              ),
              textpart('phoneNumber', false),
              PhoneNumberTextField(
                mineFocus: phoneFocusNode,
                controller: phoneController,
                requestFocus: userNameFocusNode,
                disabled: true,
              ),
              textpart('balance', false),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'balance'.tr} :',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        balance,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 25,
              ),
              AgreeButton(
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }
}
