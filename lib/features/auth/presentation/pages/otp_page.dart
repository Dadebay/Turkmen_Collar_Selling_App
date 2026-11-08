import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_input_text_field/pin_input_text_field.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firebase_messaging_service.dart';
import '../../../../core/services/sms_otp_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/buttons/agree_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../injection_container.dart';
import '../../../home/presentation/bloc/balance/balance_bloc.dart';
import '../bloc/auth_bloc.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({required this.phoneNumber, super.key});
  final String phoneNumber;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const int _otpLength = 5;

  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();

  bool _verificationInProgress = false;
  String? _codeErrorKey;

  @override
  void initState() {
    super.initState();
    otpController.addListener(_onCodeChanged);
    final sms = sl<SmsOtpService>();
    if (kDebugMode) {
      debugPrint(
        '[SMS OTP] screen opened; listenerActive=${sms.isListening}; pendingCode=${sms.latestCode.value != null}',
      );
    }
    sms.latestCode.addListener(_applyIncomingCode);
    if (!sms.isListening) {
      unawaited(sms.startListening());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyIncomingCode();
      }
    });
    unawaited(sms.debugPrintAppSignature());
  }

  void _applyIncomingCode() {
    if (!mounted) {
      return;
    }
    final code = sl<SmsOtpService>().latestCode.value;
    if (code == null || code == otpController.text) {
      return;
    }
    if (kDebugMode) {
      debugPrint('[SMS OTP] screen: applying received code to field');
    }
    otpController.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
  }

  void _onCodeChanged() {
    if (!mounted) {
      return;
    }
    if (_codeErrorKey != null) {
      setState(() => _codeErrorKey = null);
    }
    if (kDebugMode) {
      debugPrint(
        '[SMS OTP] field changed; digits=${otpController.text.length}',
      );
    }
    if (otpController.text.length == _otpLength) {
      unawaited(_processOtp());
    }
  }

  Future<void> _processOtp() async {
    if (_verificationInProgress) {
      return;
    }

    final otp = otpController.text.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(otp)) {
      setState(() => _codeErrorKey = 'otpIncomplete');
      return;
    }

    setState(() {
      _verificationInProgress = true;
      _codeErrorKey = null;
    });
    String? deviceToken;
    try {
      deviceToken = await FirebaseMessagingService.instance().getToken();
    } catch (_) {
      // The token is optional for OTP verification.
    }
    if (!mounted) {
      return;
    }
    context.read<AuthBloc>().add(
      AuthVerifyOtpRequested(
        phone: widget.phoneNumber,
        otp: otp,
        deviceToken: deviceToken,
      ),
    );
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('[SMS OTP] screen closed');
    }
    otpController.removeListener(_onCodeChanged);
    sl<SmsOtpService>().latestCode.removeListener(_applyIncomingCode);
    unawaited(sl<SmsOtpService>().stopListening());
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpVerified) {
          context.read<BalanceBloc>().add(const BalanceFetchRequested());
          context.go(AppRoutes.home);
        } else if (state is AuthError) {
          _verificationInProgress = false;
          setState(() => _codeErrorKey = 'otpErrorSubtitle');
        }
      },
      child: Scaffold(
        backgroundColor: AppPalette.of(context).surfaceAlt,
        appBar: const CustomAppBar(title: 'otpCheck', showBackButton: true),
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
                  child: _otpContent(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpContent(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 78,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorConstants.primaryColor.withOpacity(.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.sms_rounded,
            size: 38,
            color: ColorConstants.primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'otpSubtitle'.tr,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            color: palette.text,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'waitForSms'.tr,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: palette.muted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 18,
                color: ColorConstants.primaryColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.phoneNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
                'otp'.tr,
                style: textTheme.titleMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 60,
                child: PinInputTextField(
                  pinLength: _otpLength,
                  autoFocus: true,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: BoxLooseDecoration(
                    radius: const Radius.circular(12),
                    strokeWidth: 1.5,
                    gapSpace: 8,
                    textStyle: TextStyle(
                      fontSize: 26,
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                    ),
                    strokeColorBuilder: _codeErrorKey == null
                        ? PinListenColorBuilder(
                            ColorConstants.primaryColor,
                            palette.border,
                          )
                        : const FixedColorBuilder(ColorConstants.redColor),
                    bgColorBuilder: FixedColorBuilder(palette.surfaceAlt),
                  ),
                  controller: otpController,
                  focusNode: otpFocusNode,
                  onSubmit: (_) => _processOtp(),
                ),
              ),
              if (_codeErrorKey != null) ...[
                const SizedBox(height: 10),
                Text(
                  _codeErrorKey!.tr,
                  style: textTheme.bodySmall?.copyWith(
                    color: ColorConstants.redColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) => Center(
                  child: AgreeButton(
                    onTap: _processOtp,
                    isLoading: state is AuthLoading || _verificationInProgress,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
