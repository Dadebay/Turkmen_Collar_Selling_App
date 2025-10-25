import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:yaka2/app/feature/cart/services/downloads_service.dart';
import 'package:yaka2/app/feature/home/controllers/balance_controller.dart';
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';
import 'package:yaka2/app/feature/user_profil/views/add_money_phone.dart';
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
              textAlign: TextAlign.center,
              maxLines: 2,
              style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.blackColor, fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.to(() => AddMoneyPhone());
            },
            child: AnimatedContainer(
              decoration: BoxDecoration(borderRadius: CustomBorderRadius.normalBorderRadius, color: ColorConstants.primaryColor),
              padding: EdgeInsets.symmetric(horizontal: 8),
              width: Get.size.width,
              duration: const Duration(milliseconds: 1000),
              height: WidgetSizes.size80.value,
              alignment: Alignment.center,
              child: Text(
                'payment'.tr,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.whiteColor, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
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
            child: AnimatedContainer(
              decoration: BoxDecoration(borderRadius: CustomBorderRadius.normalBorderRadius, color: ColorConstants.primaryColor),
              padding: EdgeInsets.symmetric(horizontal: 8),
              width: Get.size.width,
              duration: const Duration(milliseconds: 1000),
              height: WidgetSizes.size80.value,
              alignment: Alignment.center,
              child: Text(
                'onlinePayment'.tr,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.whiteColor, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnlineAddMoneyToWallet extends StatefulWidget {
  const OnlineAddMoneyToWallet({
    required this.url,
    required this.amount,
    super.key,
  });

  final String url;
  final String amount;

  @override
  State<OnlineAddMoneyToWallet> createState() => _OnlineAddMoneyToWalletState();
}

class _OnlineAddMoneyToWalletState extends State<OnlineAddMoneyToWallet> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'onlinePayment', showBackButton: true),
      body: WebViewWidget(controller: _controller),
    );
  }
}
