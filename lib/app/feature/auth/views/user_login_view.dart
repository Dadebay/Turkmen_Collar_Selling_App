// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:yaka2/app/feature/auth/services/sign_in_service.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/home/controllers/home_controller.dart';
import 'package:yaka2/app/feature/product_profil/controllers/product_profil_controller.dart';

import '../../../product/constants/index.dart';

class UserLoginView extends StatefulWidget {
  @override
  State<UserLoginView> createState() => _UserLoginViewState();
}

class _UserLoginViewState extends State<UserLoginView> {
  final TextEditingController phoneNumberController = TextEditingController();
  final FocusNode phoneNumberFocusNode = FocusNode();
  final login = GlobalKey<FormState>();
  final HomeController homeController = Get.find();
  final ProductProfilController userProfilController = Get.put(ProductProfilController());
  final BalanceController balanceController = Get.find<BalanceController>();

  @override
  void initState() {
    super.initState();
    homeController.agreeButton.value = false;
    phoneNumberFocusNode.addListener(() {
      userProfilController.userKeyboardOpen.value = phoneNumberFocusNode.hasFocus;
    });
  }

  Future<void> onTap() async {
    homeController.agreeButton.toggle();
    if (login.currentState!.validate()) {
      if (homeController.agreeButton.value) {
        await SignInService().login(phone: '+993${phoneNumberController.text}');
        balanceController.userMoney();
      }
    } else {
      showSnackBar('noConnection3', 'errorEmpty', ColorConstants.redColor);
    }
    homeController.agreeButton.toggle();
  }

  Widget _logo() {
    return Obx(() {
      return Container(
        height: userProfilController.userKeyboardOpen.value ? Get.size.height / 5 : Get.size.height / 2.5,
        width: Get.size.width,
        color: ColorConstants.primaryColor,
        child: Image.asset(
          IconConstants.logo,
          width: WidgetSizes.size256.value,
          height: WidgetSizes.size256.value,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      appBar: CustomAppBar(title: 'login', showBackButton: true),
      body: ListView(
        children: [
          _logo(),
          Form(
            key: login,
            child: Padding(
              padding: context.padding.normal,
              child: Column(
                children: [
                  Text(
                    'signInDialog'.tr,
                    textAlign: TextAlign.center,
                    style: context.general.textTheme.titleLarge!.copyWith(
                      color: ColorConstants.blackColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Padding(
                    padding: context.padding.verticalNormal,
                    child: PhoneNumberTextField(
                      mineFocus: phoneNumberFocusNode,
                      controller: phoneNumberController,
                      requestFocus: phoneNumberFocusNode,
                    ),
                  ),
                  Center(child: AgreeButton(onTap: onTap)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
