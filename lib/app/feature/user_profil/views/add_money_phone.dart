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
                  text: 'Näme üçin 20 manatdan az töleg geçirmek bolanok - ',
                ),
                TextSpan(
                  text: 'doly bilmek üçin basyň',
                  style: TextStyle(
                    color: Colors.blue, // Burada Tap me kısmını mavi yapabilirsiniz
                    decoration: TextDecoration.underline, // Altı çizili yapmak isterseniz
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Get.defaultDialog(
                        title: 'attention'.tr,
                        middleText:
                            'Gündelik kabul edilýän tölegleriñ sanynda çäklendirme barlygy sebäpli 20 manatdan az töleg geçirmek bolanok. Hasabyñyza 20 manat geçireniñizden soñ, 2 manatlyk zat satyn alsañyz  20-2=18    2 manadyñyz kemelýär, galan 18 manadyñyz siziñ hasabyñyzda durýar. Programmany pozup ýa-da telefony çalyşan ýagdaýyñyzda hem puluñyz ýitmeýär. Agza bolan telefon belgiñizi täzeden ýazyp girseñiz puluñyz programmañ içinde durýar.',
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
                          text: 'Bankomatdan-terminaldan töleg geçirmek ',
                        ),
                        TextSpan(
                          text: 'bolanok XXXX',
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
                        text: 'Töleg programmasyndan töleg geçirmek ',
                      ),
                      TextSpan(
                        text: 'bolanok XXXX',
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
                    text: 'Töleg geçirýän telefon belgiňize jaň etmek sms ýazmak ',
                  ),
                  TextSpan(
                    text: 'bolanok XXXX',
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
                        text: 'Habarlaşmak üçin  ',
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
                        text: ' belgä jaň ediň ýada sms ýazyň.\nIş wagty ',
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
                        text: ' aralyk',
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
            child: SizedBox(
              height: 50.0, // Yüksekliği ihtiyacınıza göre ayarlayabilirsiniz

              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: moneyList.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => setState(() => value = index),
                    child: Row(
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
                  );
                },
              ),
            ),
          ),
          AgreeButton(
            text: 'payment'.tr,
            onTap: () async {
              Get.defaultDialog(
                title: 'attention'.tr,
                middleText: 'paymentWarning'.tr + '\n\n${number} belgiden töleg geçirmeli, basşga belgiden töleg geçirmek bolanok.',
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
