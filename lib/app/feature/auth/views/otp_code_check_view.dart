import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:yaka2/app/feature/auth/services/sign_in_service.dart';
import 'package:yaka2/app/product/buttons/agree_button.dart';
import 'package:yaka2/app/product/constants/color_constants.dart';
import 'package:yaka2/app/product/custom_widgets/custom_app_bar.dart';
import 'package:yaka2/app/product/custom_widgets/widgets.dart';

class OTPCodeCheckView extends StatefulWidget {
  final String phoneNumber;

  const OTPCodeCheckView({required this.phoneNumber, super.key});

  @override
  State<OTPCodeCheckView> createState() => _OTPCodeCheckViewState();
}

class _OTPCodeCheckViewState extends State<OTPCodeCheckView> with CodeAutoFill {
  final otpCheck = GlobalKey<FormState>();
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    listenForCode();
    function();
  }

  dynamic function() async {
    final String signature = await SmsAutoFill().getAppSignature;
    print('Signature: $signature');
    print('Signature: $signature');
    print('Signature: $signature');
    print('Signature: $signature');
  }

  @override
  void codeUpdated() {
    setState(() {
      otpController.text = code!;
    });
    _processOtp();
  }

  Future<void> _processOtp() async {
    if (otpCheck.currentState?.validate() ?? false) {
      try {
        await SignInService().otpCheck(otp: otpController.text, phoneNumber: widget.phoneNumber);
      } catch (_) {
        showSnackBar('otpError', 'otpVerificationFailed', ColorConstants.redColor);
      }
    } else {
      showSnackBar('noConnection3', 'errorEmpty', ColorConstants.redColor);
    }
  }

  @override
  void dispose() {
    cancel();
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'otpCheck', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'otpSubtitle'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: ColorConstants.blackColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'waitForSms'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: ColorConstants.greyColor.withOpacity(.8),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 20),
          Form(
            key: otpCheck,
            child: PinFieldAutoFill(
              codeLength: 5,
              decoration: UnderlineDecoration(
                textStyle: TextStyle(fontSize: 25, color: Colors.black, fontWeight: FontWeight.bold),
                colorBuilder: FixedColorBuilder(Colors.black),
              ),
              controller: otpController,
              focusNode: otpFocusNode,
              onCodeSubmitted: (val) => _processOtp(),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: AgreeButton(onTap: _processOtp)),
        ],
      ),
    );
  }
}
