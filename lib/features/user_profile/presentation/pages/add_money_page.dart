// ignore_for_file: always_put_control_body_on_new_line
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/border_radius_constants.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/result/result.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../features/payment/data/datasources/payment_transaction_remote_data_source.dart';
import '../../../../features/payment/data/datasources/phone_payment_limit_remote_data_source.dart';
import '../../../../features/payment/domain/entities/phone_payment_limit_result.dart';
import '../../../../features/payment/presentation/bloc/payment_status_bloc.dart';
import '../../../../injection_container.dart';
import 'add_money_phone_page.dart';
import '../../../../core/icons/app_icon.dart';

class AddMoneyPage extends StatefulWidget {
  const AddMoneyPage({super.key});

  @override
  State<AddMoneyPage> createState() => _AddMoneyPageState();
}

class _AddMoneyPageState extends State<AddMoneyPage> {
  int value = 0;
  String number = '';
  PhonePaymentLimitResult _phonePaymentLimit = PhonePaymentLimitResult.empty();
  bool _isCheckingPhoneLimit = false;
  bool _isStartingCardPayment = false;
  bool _isOpeningPhonePayment = false;
  int _limitRequestId = 0;
  Timer? _phoneLimitTimer;
  Duration _phoneLimitRemaining = Duration.zero;

  final List<int> moneyList = const [20, 30, 40, 50];

  int get _selectedAmount => moneyList[value];

  bool get _isPhonePaymentBlocked =>
      _phonePaymentLimit.activeAt != null &&
      _phonePaymentLimit.hasDailyLimit(_selectedAmount) &&
      !_phonePaymentLimit.isAvailable;

  bool get _canUsePhonePayment =>
      _phonePaymentLimit.isAvailable &&
      _phonePaymentLimit.phoneNumber.isNotEmpty &&
      _phonePaymentLimit.isAmountAvailable(_selectedAmount);

  @override
  void initState() {
    super.initState();
    number = sl<LocalStorage>().phone ?? '';
    _refreshPhonePaymentLimit();
  }

  @override
  void dispose() {
    _phoneLimitTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPhonePaymentLimit() async {
    final requestId = ++_limitRequestId;
    setState(() => _isCheckingPhoneLimit = true);
    final result = await sl<PhonePaymentLimitRemoteDataSource>()
        .checkAvailability(amount: _selectedAmount);
    if (!mounted || requestId != _limitRequestId) return;
    setState(() {
      _phonePaymentLimit = result;
      _isCheckingPhoneLimit = false;
    });
    _schedulePhoneLimitTimer();
  }

  void _schedulePhoneLimitTimer() {
    _phoneLimitTimer?.cancel();
    if (!_isPhonePaymentBlocked || _phonePaymentLimit.activeAt == null) return;
    _updatePhoneLimitRemaining();
    _phoneLimitTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updatePhoneLimitRemaining(),
    );
  }

  void _updatePhoneLimitRemaining() {
    final activeAt = _phonePaymentLimit.activeAt;
    if (activeAt == null) {
      _phoneLimitTimer?.cancel();
      if (mounted) setState(() => _phoneLimitRemaining = Duration.zero);
      return;
    }
    final remaining = activeAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _phoneLimitTimer?.cancel();
      if (mounted) setState(() => _phoneLimitRemaining = Duration.zero);
      _refreshPhonePaymentLimit();
      return;
    }
    if (mounted) setState(() => _phoneLimitRemaining = remaining);
  }

  void _selectAmount(int index) {
    if (value == index) return;
    setState(() => value = index);
    _refreshPhonePaymentLimit();
  }

  Future<void> _showPhoneLimitDialog() async {
    final activeAt = _phonePaymentLimit.activeAt;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('attention'.tr),
          content: Text(
            [
              'phonePaymentLimitBlocked'.tr
                  .replaceAll('@min', '20')
                  .replaceAll('@max', '49'),
              if (activeAt != null)
                'phonePaymentLimitActiveAt'.tr.replaceAll(
                  '@time',
                  _formatDateTime(activeAt),
                ),
              'phonePaymentLimitUseCard'.tr,
            ].join('\n\n'),
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

  Future<void> _startPhonePayment() async {
    if (_isOpeningPhonePayment || _isCheckingPhoneLimit) return;
    if (_isPhonePaymentBlocked) {
      await _showPhoneLimitDialog();
      return;
    }
    if (!_canUsePhonePayment) {
      showSnackBar(
        context,
        'notWork',
        'notWorkSubtitle',
        ColorConstants.redColor,
      );
      return;
    }
    setState(() => _isOpeningPhonePayment = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AddMoneyPhonePage(amount: _selectedAmount),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningPhonePayment = false);
        unawaited(_refreshPhonePaymentLimit());
      }
    }
  }

  Future<void> _startCardPayment() async {
    if (_isStartingCardPayment) return;
    if (context.read<PaymentStatusBloc>().state.isDisabled) {
      showSnackBar(
        context,
        'notWork',
        'notWorkSubtitle',
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
    setState(() => _isStartingCardPayment = true);
    final amount = _selectedAmount;
    try {
      final result = await sl<PaymentTransactionRemoteDataSource>()
          .sendTransactionSMS(sender: number, amount: '$amount');
      if (!mounted) return;
      if (result is Success<String>) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OnlineAddMoneyToWallet(
              url: result.dataOrThrow,
              amount: '$amount',
            ),
          ),
        );
      } else {
        showSnackBar(
          context,
          'errorTitle',
          'paymentInitiationFailed',
          ColorConstants.redColor,
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingCardPayment = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    String twoDigits(int v) => v.toString().padLeft(2, '0');
    final local = dateTime.toLocal();
    return '${twoDigits(local.day)}.${twoDigits(local.month)}.${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.surfaceAlt,
      appBar: CustomAppBar(
        title: 'addCash',
        showBackButton: true,
        actionButton: IconButton(
          onPressed: () {
            final isLoggedIn = (LocalStorage().token ?? '').isNotEmpty;
            if (!isLoggedIn) {
              context.push(AppRoutes.login);
              return;
            }
            context.push(AppRoutes.aiChat);
          },
          icon: AppIcon(
            IconlyLight.message,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
      ),
      body: BlocBuilder<PaymentStatusBloc, PaymentStatusState>(
        builder: (context, paymentState) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                children: [
                  _buildIntroCard(context),
                  const SizedBox(height: 24),
                  if (paymentState.isDisabled)
                    _buildPaymentUnavailable(context)
                  else ...[
                    _buildSectionTitle(context, 'selectAmountTitle'.tr),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: moneyList.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.25,
                          ),
                      itemBuilder: (context, index) =>
                          _buildAmountOption(context, index),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSectionTitle(
                            context,
                            'selectPaymentMethodTitle'.tr,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: ColorConstants.primaryColor.withOpacity(.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_selectedAmount TMT',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ColorConstants.primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodCard(
                      context,
                      icon: Icons.sms_outlined,
                      title: 'payment'.tr,
                      description: 'addMoneyPhoneDescription'.tr,
                      status: _phonePaymentStatusText,
                      statusColor: _phonePaymentStatusColor,
                      available: _canUsePhonePayment,
                      isLoading: _isOpeningPhonePayment,
                      onTap: _isCheckingPhoneLimit ? null : _startPhonePayment,
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethodCard(
                      context,
                      icon: Icons.credit_card_rounded,
                      title: 'onlinePayment'.tr,
                      description: 'addMoneyCardDescription'.tr,
                      available: true,
                      isLoading: _isStartingCardPayment,
                      onTap: _isStartingCardPayment ? null : _startCardPayment,
                    ),
                    const SizedBox(height: 16),
                    _buildPhoneLimitNotice(context),
                    _buildMinimumPaymentNotice(context),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String get _phonePaymentStatusText {
    if (_isCheckingPhoneLimit) return 'phonePaymentLimitChecking'.tr;
    if (_canUsePhonePayment) return 'phonePaymentLimitOpen'.tr;
    if (_isPhonePaymentBlocked) return 'addMoneyPhoneLimited'.tr;
    return 'addMoneyPhoneUnavailable'.tr;
  }

  Color get _phonePaymentStatusColor {
    if (_isCheckingPhoneLimit) return AppPalette.of(context).muted;
    if (_canUsePhonePayment) return ColorConstants.greenColor;
    return ColorConstants.redColor;
  }

  Widget _buildIntroCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 14),
          Text(
            'addMoneyIntroTitle'.tr,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'addMoneyIntroDescription'.tr,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_iphone_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'addMoneyAccountLabel'.tr,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        number.isEmpty ? 'addMoneySignInHint'.tr : number,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentUnavailable(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, color: palette.muted, size: 36),
          const SizedBox(height: 12),
          Text(
            'notWorkSubtitle'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: palette.text, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.general.textTheme.titleMedium!.copyWith(
        color: AppPalette.of(context).text,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildAmountOption(BuildContext context, int index) {
    final amount = moneyList[index];
    final isSelected = value == index;
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$amount TMT',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isStartingCardPayment || _isOpeningPhonePayment
            ? null
            : () => _selectAmount(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorConstants.primaryColor.withOpacity(.1)
                : palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? ColorConstants.primaryColor : palette.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '$amount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'TMT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected
                    ? ColorConstants.primaryColor
                    : palette.border,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool available,
    required bool isLoading,
    required VoidCallback? onTap,
    String? status,
    Color? statusColor,
  }) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: ColorConstants.primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.muted, height: 1.35),
                    ),
                    if (status != null) ...[
                      const SizedBox(height: 9),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor ?? palette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 11),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        available
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.info_outline_rounded,
                        color: available
                            ? ColorConstants.primaryColor
                            : palette.muted,
                        size: 19,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneLimitNotice(BuildContext context) {
    if (_isCheckingPhoneLimit || !_isPhonePaymentBlocked) {
      return const SizedBox.shrink();
    }
    const color = ColorConstants.redColor;
    final activeAt = _phonePaymentLimit.activeAt;
    final text = activeAt != null
        ? 'phonePaymentLimitBlockedUntil'.tr
              .replaceAll('@min', '20')
              .replaceAll('@max', '49')
              .replaceAll('@time', _formatDateTime(activeAt))
        : 'phonePaymentLimitBlocked'.tr
              .replaceAll('@min', '20')
              .replaceAll('@max', '49');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: CustomBorderRadius.normalBorderRadius,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon(Icons.schedule_rounded, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: context.general.textTheme.bodyMedium!.copyWith(
                    color: AppPalette.of(context).text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (activeAt != null) ...[
            const SizedBox(height: 12),
            _buildPhoneLimitCountdown(context),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimumPaymentNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.secondaryColor.withOpacity(0.06),
        borderRadius: CustomBorderRadius.normalBorderRadius,
        border: Border.all(
          color: ColorConstants.secondaryColor.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(
            Icons.info_outline,
            color: ColorConstants.secondaryColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'addMoneyMinimumNotice'.tr,
              style: context.general.textTheme.bodySmall!.copyWith(
                color: AppPalette.of(context).text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLimitCountdown(BuildContext context) {
    final activeAt = _phonePaymentLimit.activeAt;
    final remaining = activeAt == null ? Duration.zero : _phoneLimitRemaining;
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildPhoneLimitTimeBox(context, hours, 'addMoneyHours'.tr),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPhoneLimitTimeBox(
            context,
            minutes,
            'addMoneyMinutes'.tr,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPhoneLimitTimeBox(
            context,
            seconds,
            'addMoneySeconds'.tr,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLimitTimeBox(
    BuildContext context,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: context.general.textTheme.titleMedium!.copyWith(
              color: AppPalette.of(context).text,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.general.textTheme.bodySmall!.copyWith(
              color: AppPalette.of(context).muted,
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
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _controller.runJavaScript('''
              var meta = document.createElement('meta');
              meta.name = 'viewport';
              meta.content = 'width=device-width, initial-scale=1.0, minimum-scale=0.5, maximum-scale=5.0, user-scalable=yes';
              document.getElementsByTagName('head')[0].appendChild(meta);
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'onlinePayment', showBackButton: true),
      body: WebViewWidget(controller: _controller),
    );
  }
}
