import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:yaka2/app/feature/cart/services/downloads_service.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';
import 'package:yaka2/app/product/constants/index.dart';

import '../../auth/models/auth_model.dart';
import '../../auth/views/user_login_view.dart';

class AddMoneyPhone extends StatefulWidget {
  const AddMoneyPhone({Key? key}) : super(key: key);

  @override
  State<AddMoneyPhone> createState() => _AddMoneyPhoneState();
}

class _AddMoneyPhoneState extends State<AddMoneyPhone> {
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

  List moneyList = [20, 30, 40, 50];
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
              style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.blackColor, fontWeight: FontWeight.w500, fontSize: 20),
            ),
          ),
          Padding(
            padding: context.padding.verticalNormal,
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return RadioListTile(
                  value: index,
                  activeColor: ColorConstants.primaryColor,
                  groupValue: value,
                  onChanged: (int? ind) => setState(() => value = ind!),
                  title: Text(
                    '${moneyList[index]} TMT',
                    style: const TextStyle(
                      color: ColorConstants.blackColor, //fontFamily: normProBold,
                      fontSize: 18,
                    ),
                  ),
                );
              },
              itemCount: moneyList.length,
            ),
          ),
          AgreeButton(
            text: 'payment'.tr,
            onTap: () async {
              Get.defaultDialog(
                title: 'attention'.tr,
                middleText: 'paymentWarning'.tr,
                textCancel: 'no'.tr,
                textConfirm: 'ok'.tr,
                confirmTextColor: ColorConstants.whiteColor,
                buttonColor: ColorConstants.primaryColor,
                onConfirm: () async {
                  Get.back();
                  final token = await Auth().getToken();
                  if (token == null || token == '') {
                    showSnackBar('loginError', 'loginErrorSubtitle1', ColorConstants.redColor);
                    await Get.to(() => UserLoginView());
                  } else {
                    await DownloadsService().getAvailabePhoneNumber().then((element) async {
                      final String phoneNumber = element['data'][0];
                      if (Platform.isAndroid) {
                        final uri = 'sms:0804?body=$phoneNumber   ${moneyList[value]} ';
                        await launchUrlString(uri);
                      } else if (Platform.isIOS) {
                        final uri = 'sms:0804&body=$phoneNumber   ${moneyList[value]} ';
                        await launchUrlString(uri);
                      }
                    });
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
