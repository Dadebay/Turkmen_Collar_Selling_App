import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:yaka2/app/feature/cart/services/downloads_service.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';
import 'package:yaka2/app/feature/user_profil/views/add_money.dart';
import 'package:yaka2/app/product/constants/index.dart';

import '../../auth/models/auth_model.dart';
import '../../auth/views/user_login_view.dart';

class AddMoneyCard extends StatefulWidget {
  const AddMoneyCard({Key? key}) : super(key: key);

  @override
  State<AddMoneyCard> createState() => _AddMoneyCardState();
}

class _AddMoneyCardState extends State<AddMoneyCard> {
  int value = 0;
  String number = '';
  final BalanceController controller = Get.find();
  @override
  void initState() {
    super.initState();
    controller.returnPhoneNumber().then((value) {
      number = value;
      setState(() {});
    });
  }

  List moneyList = [10, 20, 30, 40, 50];
  final UserProfilController userProfilController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'addCash',
        showBackButton: true,
        actionButton: IconButton(
          onPressed: () async {
            await launchUrlString('tel://${userProfilController.phoneNumber.value}');
          },
          icon: const Icon(
            IconlyLight.call,
            color: ColorConstants.whiteColor,
          ),
        ),
      ),
      body: ListView(
        padding: context.padding.normal,
        children: [
          Row(
            children: [
              Text(
                'myNumber'.tr,
                style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.greyColor, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  number,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.blackColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Padding(
            padding: context.padding.verticalMedium,
            child: Text(
              'addMoneyTitle1'.tr,
              textAlign: TextAlign.center,
              style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.redColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: context.general.textTheme.titleLarge!.copyWith(
                color: ColorConstants.blackColor,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              children: [
                TextSpan(
                  text: 'whyLessThan20Title'.tr,
                ),
                TextSpan(
                  text: 'whyLessThan20Subtitle'.tr,
                  style: TextStyle(
                    color: Colors.blue, // Burada Tap me kısmını mavi yapabilirsiniz
                    decoration: TextDecoration.underline, // Altı çizili yapmak isterseniz
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Get.defaultDialog(
                        title: 'attention'.tr,
                        middleText: 'whyLessThan20Info'.tr,
                        textConfirm: 'ok'.tr,
                        confirmTextColor: ColorConstants.whiteColor,
                        buttonColor: ColorConstants.primaryColor,
                        onConfirm: () async {
                          Get.back();
                        },
                      );
                    },
                ),
              ],
            ),
          ),
          Padding(
            padding: context.padding.verticalMedium,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/image/atm-machine.png',
                  width: 24,
                  height: 24,
                ),
                Expanded(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: context.general.textTheme.titleLarge!.copyWith(
                        color: ColorConstants.blackColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: 'paymentFromATM'.tr,
                        ),
                        TextSpan(
                          text: 'notPossible'.tr,
                          style: TextStyle(
                            color: Colors.red, // Burada Tap me kısmını mavi yapabilirsiniz
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/image/toleg.png',
                width: 24,
                height: 24,
              ),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: context.general.textTheme.titleLarge!.copyWith(
                      color: ColorConstants.blackColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    children: [
                      TextSpan(
                        text: 'paymentFromApp'.tr,
                      ),
                      TextSpan(
                        text: 'notPossible'.tr,
                        style: TextStyle(
                          color: Colors.red, // Burada Tap me kısmını mavi yapabilirsiniz
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: context.padding.verticalMedium,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: context.general.textTheme.titleLarge!.copyWith(
                  color: ColorConstants.blackColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(
                    text: 'callOrSmsNotPossible'.tr,
                  ),
                  TextSpan(
                    text: 'notPossible'.tr,
                    style: TextStyle(
                      color: Colors.red, // Burada Tap me kısmını mavi yapabilirsiniz
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.call, size: 24, color: ColorConstants.blackColor),
              Expanded(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: context.general.textTheme.titleLarge!.copyWith(
                      color: ColorConstants.blackColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    children: [
                      TextSpan(
                        text: 'forContact'.tr,
                      ),
                      TextSpan(
                        text: userProfilController.phoneNumber.value,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            await launchUrlString('tel://${userProfilController.phoneNumber.value}');
                          },
                        style: TextStyle(
                          color: Colors.black, // Burada Tap me kısmını mavi yapabilirsiniz
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline, // Altı çizili yapmak isterseniz
                        ),
                      ),
                      TextSpan(
                        text: 'callOrSmsToNumber'.tr,
                        style: TextStyle(
                          color: Colors.black, // Burada Tap me kısmını mavi yapabilirsiniz
                        ),
                      ),
                      TextSpan(
                        text: '9:00 - 20:00',
                        style: TextStyle(
                          color: Colors.red, // Burada Tap me kısmını mavi yapabilirsiniz
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: 'workingHoursInterval'.tr,
                        style: TextStyle(
                          color: Colors.black, // Burada Tap me kısmını mavi yapabilirsiniz
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: context.padding.verticalNormal,
            child: Wrap(
              spacing: 8.0, // Yatay boşluk
              runSpacing: 8.0, // Dikey boşluk (satırlar arası)
              alignment: WrapAlignment.center,
              children: List.generate(
                moneyList.length,
                (index) => InkWell(
                  onTap: () => setState(() => value = index),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: value,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeColor: ColorConstants.primaryColor,
                        onChanged: (int? ind) => setState(() => value = ind!),
                      ),
                      Text(
                        '${moneyList[index]} TMT',
                        style: const TextStyle(
                          color: ColorConstants.blackColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AgreeButton(
            text: 'onlinePayment'.tr,
            onTap: () async {
              final token = await Auth().getToken();
              if (token == null || token == '') {
                showSnackBar('loginError', 'loginErrorSubtitle1', ColorConstants.redColor);
                await Get.to(() => UserLoginView());
              } else {
                final formUrl = await userProfilController.sendTransactionSMS(
                  sender: number,
                  amount: moneyList[value].toString(),
                );

                if (formUrl != null) {
                  await Get.to(
                    () => OnlineAddMoneyToWallet(
                      url: formUrl,
                      amount: moneyList[value].toString(),
                    ),
                  );
                } else {
                  showSnackBar('Error', 'Unable to initiate payment', ColorConstants.redColor);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
