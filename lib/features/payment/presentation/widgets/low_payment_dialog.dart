import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/constants/icon_constants.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/payment_gate_service.dart';
import '../../../../core/theme/color_constants.dart';

/// The backend's raw `amount` / `total_amount`, kept in a notifier so a second
/// `AMOUNT_TOO_LOW` push refreshes an already-open dialog in place instead of
/// stacking another one on top. Stored unformatted so the resulting-balance
/// promise is derived at render time.
final ValueNotifier<({String amount, String rawTotalAmount})> _gateAmounts =
    ValueNotifier<({String amount, String rawTotalAmount})>((
      amount: '0',
      rawTotalAmount: '0',
    ));

bool _gateOpen = false;

/// Held across the navigator-wait below so a push arriving while the startup
/// check is still waiting refreshes the figures instead of racing it to
/// `showDialog` and stacking a second gate.
bool _gateOpening = false;

double _parseAmount(String raw) =>
    double.tryParse(raw.replaceAll(',', '.')) ?? 0;

/// The gate always asks for the same [_topUpAmount]; what the dialog promises
/// is the balance the user ends up with once they pay it. Formatted with a
/// comma decimal separator to match the rest of the Turkmen UI.
String _formatResultingBalance(String rawTotalAmount) =>
    (_parseAmount(rawTotalAmount) + _topUpAmount)
        .toStringAsFixed(2)
        .replaceAll('.', ',');

/// The fixed top-up the gate demands, in TMT.
const int _topUpAmount = 20;

/// Opens (or refreshes) the blocking "you paid less than 20 TMT" gate.
///
/// [rawTotalAmount] is the backend's `total_amount` — the +20 promise is
/// applied here so every caller renders the same figure.
Future<void> showLowPaymentGate({
  required String amount,
  required String rawTotalAmount,
}) async {
  _gateAmounts.value = (amount: amount, rawTotalAmount: rawTotalAmount);

  if (_gateOpen || _gateOpening) {
    log('🔄 [PAYMENT GATE] Refreshed amounts on the pending dialog');
    return;
  }

  _gateOpening = true;
  try {
    // A push that resolves from a terminated start can land before the first
    // frame, so wait briefly for the navigator rather than dropping the gate.
    var context = rootNavigatorKey.currentContext;
    for (var attempt = 0; context == null && attempt < 10; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      context = rootNavigatorKey.currentContext;
    }
    if (context == null) {
      log('⚠️ [PAYMENT GATE] Navigator never became available, gate skipped');
      return;
    }

    _gateOpen = true;
    log('🚨 [PAYMENT GATE] Opening AMOUNT_TOO_LOW dialog');
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _LowPaymentDialog(),
      ).whenComplete(() => _gateOpen = false),
    );
  } finally {
    _gateOpening = false;
  }
}

/// Closes the gate if it is showing. Safe to call unconditionally.
void dismissLowPaymentGate() {
  if (!_gateOpen) {
    return;
  }
  // The gate is a modal barrier, so it is always the top route.
  _gateOpen = false;
  rootNavigatorKey.currentState?.pop();
}

/// Applies an incoming FCM message to the gate: opens it, or releases it once
/// the backend confirms a proper top-up.
Future<void> handleGateMessage(Map<String, dynamic> data) async {
  final flattened = PaymentGateService.flatten(data);
  final status = flattened['status']?.toString();

  if (status == PaymentGateService.statusCompleted) {
    await PaymentGateService.clear();
    dismissLowPaymentGate();
    return;
  }

  if (status == PaymentGateService.statusAmountTooLow) {
    await PaymentGateService.save(flattened);
    await showLowPaymentGate(
      amount: (flattened['amount'] ?? '0').toString(),
      rawTotalAmount: (flattened['total_amount'] ?? '0').toString(),
    );
  }
}

/// Re-arms the gate from persisted state — used on startup and on every resume,
/// so returning from the SMS app puts the user back behind it. A missing file
/// means a `COMPLETED` arrived while we were backgrounded, so close any dialog
/// left standing.
Future<void> checkPendingLowPaymentGate() async {
  final pending = await PaymentGateService.readPending();
  if (pending == null) {
    dismissLowPaymentGate();
    return;
  }
  await showLowPaymentGate(
    amount: (pending['amount'] ?? '0').toString(),
    rawTotalAmount: (pending['total_amount'] ?? '0').toString(),
  );
}

class _LowPaymentDialog extends StatelessWidget {
  const _LowPaymentDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPalette.of(context).surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(IconConstants.logo, height: 80),
              ),
              const SizedBox(height: 20),
              Text(
                'lowPaymentTitle'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppPalette.of(context).text,
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<({String amount, String rawTotalAmount})>(
                valueListenable: _gateAmounts,
                builder: (context, amounts, _) => Text(
                  'lowPaymentBody'.trParams({
                    'amount': amounts.amount,
                    'totalAmount': _formatResultingBalance(
                      amounts.rawTotalAmount,
                    ),
                  }),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppPalette.of(context).text,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ColorConstants.redColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => exit(0),
                      child: Text(
                        'lowPaymentExit'.tr,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: ColorConstants.redColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _goToTopUp,
                      child: Text(
                        'lowPaymentPay'.tr,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the phone top-up page pre-filled with the fixed [_topUpAmount], so
  /// the user reads the usual warnings and instructions before the page fires
  /// the SMS.
  ///
  /// Closes the gate before pushing: `showDialog` adds an imperative route that
  /// always sits above go_router's declarative pages, so the top-up page would
  /// otherwise render behind the modal barrier. The persisted state is left
  /// untouched, so the gate re-arms when the user comes back.
  void _goToTopUp() {
    final navigator = rootNavigatorKey.currentContext;
    dismissLowPaymentGate();
    if (navigator == null) {
      return;
    }
    unawaited(
      navigator
          .push<void>(AppRoutes.addMoneyPhone, extra: _topUpAmount)
          .then((_) => checkPendingLowPaymentGate()),
    );
  }
}
