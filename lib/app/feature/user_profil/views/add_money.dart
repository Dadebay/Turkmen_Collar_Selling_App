import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yaka2/app/feature/cart/services/file_download_service.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';
import 'package:yaka2/app/product/constants/index.dart';

import '../../auth/models/auth_model.dart';
import '../../auth/views/user_login_view.dart';

class AddCash extends StatefulWidget {
  const AddCash({Key? key}) : super(key: key);

  @override
  State<AddCash> createState() => _AddCashState();
}

class _AddCashState extends State<AddCash> {
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
              'addMoneyTitle'.tr,
              style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.blackColor, fontSize: 18),
            ),
          ),
          Text(
            'addMoneySubTitle'.tr,
            style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.redColor, fontSize: 18),
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
              itemCount: 5,
            ),
          ),
          AgreeButton(
            onTap: () async {
              final token = await Auth().getToken();
              if (token == null || token == '') {
                showSnackBar('loginError', 'loginErrorSubtitle1', ColorConstants.redColor);
                await Get.to(() => UserLoginView());
              } else {
                await FileDownloadService().getAvailabePhoneNumber().then((element) async {
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
          ),
        ],
      ),
    );
  }
}
