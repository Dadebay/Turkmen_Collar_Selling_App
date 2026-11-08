// ignore_for_file: always_put_control_body_on_new_line
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../features/payment/data/datasources/phone_payment_limit_remote_data_source.dart';
import '../../../../features/payment/domain/entities/phone_payment_limit_result.dart';
import '../../../../features/payment/presentation/bloc/payment_status_bloc.dart';
import '../../../../injection_container.dart';

class AddMoneyPhonePage extends StatefulWidget {
  const AddMoneyPhonePage({required this.amount, super.key});

  final int amount;

  @override
  State<AddMoneyPhonePage> createState() => _AddMoneyPhonePageState();
}

class _AddMoneyPhonePageState extends State<AddMoneyPhonePage> {
  String number = '';
  bool agreeInstructions = false;
  PhonePaymentLimitResult _limit = PhonePaymentLimitResult.empty();
  bool _isLoadingLimit = true;
  bool _openingSms = false;

  bool get _canPay =>
      _limit.isAvailable &&
      _limit.phoneNumber.isNotEmpty &&
      _limit.isAmountAvailable(widget.amount);

  int get _minAmount =>
      _isLoadingLimit ||
          (_limit.activeAt == null && !_limit.isAvailable) ||
          _limit.availableAmounts.isEmpty
      ? 20
      : _limit.availableAmounts.first;

  /// Server-provided phone number included in the top-up SMS body.
  String get _receiverPhone => _limit.phoneNumber;

  @override
  void initState() {
    super.initState();
    number = sl<LocalStorage>().phone ?? '';
    _loadLimit();
  }

  Future<void> _loadLimit() async {
    final result = await sl<PhonePaymentLimitRemoteDataSource>()
        .checkAvailability(amount: widget.amount);
    if (!mounted) return;
    setState(() {
      _limit = result;
      _isLoadingLimit = false;
    });
  }

  Future<void> _startPhonePayment() async {
    if (_openingSms || !agreeInstructions) return;
    if (context.read<PaymentStatusBloc>().state.isDisabled) {
      showSnackBar(
        context,
        'notWork',
        'notWorkSubtitle',
        ColorConstants.redColor,
      );
      return;
    }

    if (_isLoadingLimit || !_canPay) {
      showSnackBar(
        context,
        'notWork',
        'addMoneyPhoneUnavailable',
        ColorConstants.redColor,
      );
      return;
    }

    final token = sl<LocalStorage>().token;
    if (token == null || token.isEmpty) {
      showSnackBar(
        context,
        'loginError',
        'loginErrorSubtitle1',
        ColorConstants.redColor,
      );
      unawaited(context.push(AppRoutes.login));
      return;
    }

    setState(() => _openingSms = true);
    try {
      // Encode the body exactly once. Passing an already-encoded string into
      // Uri(queryParameters:) double-encodes it (the messaging app then shows
      // the literal %2B/%20). %20 for spaces decodes more reliably than the
      // form-encoded '+' that queryParameters would emit.
      final body = Uri.encodeComponent('$_receiverPhone   ${widget.amount}');
      final smsUri = 'sms:0804?body=$body';
      if (Platform.isIOS || Platform.isAndroid) {
        await launchUrlString(smsUri);
      }
    } catch (_) {
      if (!mounted) return;
      showSnackBar(
        context,
        'errorTitle',
        'paymentInitiationFailed',
        ColorConstants.redColor,
      );
    } finally {
      if (mounted) setState(() => _openingSms = false);
    }
  }

  void _showWhyLessThan20Dialog() {
    const second = 2;
    final result = _minAmount - second;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('attention'.tr),
          content: Text(
            'whyLessThan20Info'.tr
                .replaceAll('@min', '$_minAmount')
                .replaceAll('@second', '$second')
                .replaceAll('@result', '$result'),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('ok'.tr),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSupportChat() async {
    final token = sl<LocalStorage>().token;
    if (token == null || token.isEmpty) {
      unawaited(context.push(AppRoutes.login));
      return;
    }
    unawaited(context.push(AppRoutes.aiChat));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final ready =
        agreeInstructions && _canPay && !_isLoadingLimit && !_openingSms;
    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: const CustomAppBar(title: 'addCash', showBackButton: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              _buildSummaryCard(context),
              const SizedBox(height: 20),
              _buildStepsCard(context),
              const SizedBox(height: 14),
              _buildRulesCard(context),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _openSupportChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: Text('addMoneyPhoneHelp'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.text,
                  side: BorderSide(color: palette.border),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: palette.surface,
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CheckboxListTile(
                  value: agreeInstructions,
                  onChanged: (checked) =>
                      setState(() => agreeInstructions = checked ?? false),
                  title: Text(
                    'paymentInstructionsAgreement'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  activeColor: ColorConstants.primaryColor,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              const SizedBox(height: 10),
              if (!ready && !_openingSms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _isLoadingLimit
                        ? 'phonePaymentLimitChecking'.tr
                        : !_canPay
                        ? 'addMoneyPhoneUnavailable'.tr
                        : 'readPaymentInstructionsAgreement'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.muted),
                  ),
                ),
              FilledButton.icon(
                onPressed: ready ? _startPhonePayment : null,
                icon: _openingSms
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sms_outlined),
                label: Text('addMoneyPhoneOpenSms'.tr),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'addMoneyPhoneSummaryTitle'.tr,
            style: textTheme.titleMedium?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.amount} TMT',
            style: textTheme.headlineMedium?.copyWith(
              color: ColorConstants.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.phone_iphone_rounded, color: palette.muted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'addMoneyAccountLabel'.tr,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      number,
                      style: textTheme.titleMedium?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'addMoneyPhoneStepsTitle'.tr,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: palette.text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _buildStep(context, 1, 'addMoneyPhoneStepOne'.tr),
          const SizedBox(height: 14),
          _buildStep(context, 2, 'addMoneyPhoneStepTwo'.tr),
          const SizedBox(height: 14),
          _buildStep(context, 3, 'addMoneyPhoneStepThree'.tr),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int index, String text) {
    final palette = AppPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 27,
          height: 27,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorConstants.primaryColor.withOpacity(.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$index',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ColorConstants.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: palette.text, height: 1.35),
          ),
        ),
      ],
    );
  }

  Widget _buildRulesCard(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'addMoneyPhoneRulesTitle'.tr,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: palette.text, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _buildRule(
            context,
            Icons.info_outline_rounded,
            'addMoneyPhoneMinRule'.tr.replaceAll('@min', '$_minAmount'),
          ),
          TextButton(
            onPressed: _showWhyLessThan20Dialog,
            child: Text('whyLessThan20Subtitle'.tr),
          ),
          _buildRule(
            context,
            Icons.phone_iphone_rounded,
            'paymentWarningExtra'.tr.replaceAll('@number', number),
          ),
          const SizedBox(height: 12),
          _buildRule(
            context,
            Icons.block_rounded,
            '${'paymentFromATM'.tr}${'notPossible'.tr}. '
            '${'paymentFromApp'.tr}${'notPossible'.tr}.',
          ),
          const SizedBox(height: 12),
          _buildRule(
            context,
            Icons.block_rounded,
            '${'callOrSmsNotPossible'.tr}${'notPossible'.tr}.',
          ),
        ],
      ),
    );
  }

  Widget _buildRule(BuildContext context, IconData icon, String text) {
    final palette = AppPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ColorConstants.primaryColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: palette.text, height: 1.4),
          ),
        ),
      ],
    );
  }
}
