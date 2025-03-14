// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/auth/services/sign_in_service.dart';
import 'package:yaka2/app/feature/home/controllers/home_controller.dart';

import '../../../product/constants/index.dart';

class UserLoginView extends StatelessWidget {
  TextEditingController phoneNumberController = TextEditingController();

  FocusNode phoneNumberFocusNode = FocusNode();

  final login = GlobalKey<FormState>();

  final HomeController homeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'login', showBackButton: true),
      body: ListView(
        children: [
          _logo(),
          Form(
            key: login,
            child: Container(
              padding: context.padding.normal,
              child: Column(
                children: [
                  Text(
                    'signInDialog'.tr,
                    textAlign: TextAlign.center,
                    style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.blackColor, fontWeight: FontWeight.w800),
                  ),
                  Padding(
                    padding: context.padding.verticalNormal,
                    child: PhoneNumberTextField(
                      mineFocus: phoneNumberFocusNode,
                      controller: phoneNumberController,
                      requestFocus: phoneNumberFocusNode,
                    ),
                  ),
                  Center(
                    child: AgreeButton(
                      onTap: onTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onTap() async {
    homeController.agreeButton.toggle();
    if (login.currentState!.validate()) {
      if (homeController.agreeButton.value) {
        await SignInService().login(phone: '+993${phoneNumberController.text}');
      }
    } else {
      showSnackBar('noConnection3', 'errorEmpty', ColorConstants.redColor);
    }
    homeController.agreeButton.toggle();
  }

  Container _logo() {
    return Container(
      height: Get.size.height / 2.5,
      color: ColorConstants.primaryColor,
      child: Image.asset(
        IconConstants.logo,
        width: WidgetSizes.size256.value,
        height: WidgetSizes.size256.value,
      ),
    );
  }
}
