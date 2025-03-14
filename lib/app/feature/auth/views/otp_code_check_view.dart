// ignore_for_file: file_names, must_be_immutable

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yaka2/app/feature/auth/services/sign_in_service.dart';

import '../../../product/constants/index.dart';

class OTPCodeCheckView extends StatefulWidget {
  final String phoneNumber;

  OTPCodeCheckView({required this.phoneNumber, super.key});

  @override
  State<OTPCodeCheckView> createState() => _OTPCodeCheckViewState();
}

class _OTPCodeCheckViewState extends State<OTPCodeCheckView> {
  final otpCheck = GlobalKey<FormState>();
  TextEditingController otpController = TextEditingController();
  FocusNode otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    startListening();
  }

  void startListening() async {
    final status = await Permission.sms.request();

    if (status.isGranted) {
      final SmsQuery query = SmsQuery();
      Timer.periodic(Duration(seconds: 6), (timer) async {
        final List<SmsMessage> messages = await query.getAllSms;
        messages.sort((a, b) => b.date!.compareTo(a.date!));
        for (var message in messages) {
          if (message.body != null && message.body!.contains('Ýaka OTP:')) {
            final String? otpCode = message.body!.split('Ýaka OTP: ')[1].split(' ')[0];
            if (otpController.text != otpCode) {
              otpController.text = otpCode!;
              setState(() {});
              await onTap();
              FocusScope.of(context).unfocus();
            }
            break;
          }
        }
      });
    } else {
      showSnackBar('smsPermissionError', 'smsPermissionErrorSubtitle', ColorConstants.redColor);
    }
  }

  Future<void> onTap() async {
    if (otpCheck.currentState!.validate()) {
      await SignInService().otpCheck(otp: otpController.text, phoneNumber: '${widget.phoneNumber}');
    } else {
      showSnackBar('noConnection3', 'errorEmpty', ColorConstants.redColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'otpCheck', showBackButton: true),
      body: ListView(
        padding: context.padding.normal,
        children: [
          Text(
            'otpSubtitle'.tr,
            textAlign: TextAlign.center,
            style: context.general.textTheme.titleLarge!.copyWith(color: ColorConstants.blackColor, fontWeight: FontWeight.w800),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Text(
              'waitForSms'.tr,
              textAlign: TextAlign.center,
              style: context.general.textTheme.titleMedium!.copyWith(color: ColorConstants.greyColor.withOpacity(.8), fontWeight: FontWeight.w500),
            ),
          ),
          Form(
            key: otpCheck,
            child: CustomTextField(
              labelName: 'otp',
              controller: otpController,
              focusNode: otpFocusNode,
              requestfocusNode: otpFocusNode,
              isNumber: true,
              maxline: 1,
            ),
          ),
          SizedBox(height: context.padding.onlyTopMedium.vertical),
          Center(
            child: AgreeButton(onTap: onTap),
          ),
        ],
      ),
    );
  }
}
