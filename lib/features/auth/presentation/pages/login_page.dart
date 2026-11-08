import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/sms_otp_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/buttons/agree_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../core/widgets/phone_number_text_field.dart';
import '../../../../injection_container.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneNumberController = TextEditingController();
  final FocusNode phoneNumberFocusNode = FocusNode();
  final loginFormKey = GlobalKey<FormState>();
  bool _preparingOtp = false;
  bool _openedOtp = false;

  void _onPhoneChanged(String value) {
    if (RegExp(r'^\d{8}$').hasMatch(value)) {
      unawaited(_onTap());
    }
  }

  @override
  void dispose() {
    if (!_openedOtp) {
      unawaited(sl<SmsOtpService>().stopListening());
    }
    phoneNumberController.dispose();
    phoneNumberFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_preparingOtp) {
      return;
    }
    if (!(loginFormKey.currentState?.validate() ?? false)) {
      showSnackBar(
        context,
        'noConnection3',
        'errorEmpty',
        ColorConstants.redColor,
      );
      return;
    }
    phoneNumberFocusNode.unfocus();
    setState(() => _preparingOtp = true);
    if (kDebugMode) {
      debugPrint('[SMS OTP] login: preparing listeners before request');
    }
    await sl<SmsOtpService>().startListening();
    if (!mounted) {
      return;
    }
    final phone = '+993${phoneNumberController.text}';
    if (kDebugMode) {
      debugPrint('[SMS OTP] login: sending code request');
    }
    context.read<AuthBloc>().add(AuthSendOtpRequested(phone: phone));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          if (kDebugMode) {
            debugPrint(
              '[SMS OTP] login: code request accepted; opening OTP screen',
            );
          }
          _openedOtp = true;
          setState(() => _preparingOtp = false);
          context.push(AppRoutes.otpPath(Uri.encodeComponent(state.phone)));
        } else if (state is AuthError && _preparingOtp) {
          if (kDebugMode) {
            debugPrint('[SMS OTP] login: code request failed');
          }
          setState(() => _preparingOtp = false);
          unawaited(sl<SmsOtpService>().stopListening());
          showSnackBar(
            context,
            'noConnection3',
            'error',
            ColorConstants.redColor,
          );
        }
      },
      child: Scaffold(
        backgroundColor: palette.surfaceAlt,
        // Only offer a back button when the login page was pushed onto an
        // existing stack (guest tapping a sign-in-gated action). After logout
        // the shell does `context.go(login)`, leaving login as the root — there
        // is nothing to pop back to, so no back button should be shown.
        appBar: CustomAppBar(title: 'login', showBackButton: context.canPop()),
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48)
                    .clamp(0.0, double.infinity)
                    .toDouble(),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: loginFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 170,
                          height: 170,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ColorConstants.primaryColor,
                            borderRadius: BorderRadius.circular(36),
                          ),
                          child: const Text(
                            'YAKA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'signInDialog'.tr,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            border: Border.all(color: palette.border),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'phoneNumber'.tr,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: palette.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              PhoneNumberTextField(
                                mineFocus: phoneNumberFocusNode,
                                controller: phoneNumberController,
                                requestFocus: phoneNumberFocusNode,
                                outerPadding: EdgeInsets.zero,
                                onChanged: _onPhoneChanged,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.sms_outlined,
                                    size: 18,
                                    color: palette.muted,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'otpTitle'.tr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: palette.muted,
                                            height: 1.35,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) => Center(
                                  child: AgreeButton(
                                    onTap: _onTap,
                                    text: 'login',
                                    isLoading:
                                        _preparingOtp || state is AuthLoading,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
