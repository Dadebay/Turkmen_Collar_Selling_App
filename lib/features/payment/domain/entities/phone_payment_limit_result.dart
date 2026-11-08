// ignore_for_file: always_put_control_body_on_new_line
class PhonePaymentLimitResult {
  const PhonePaymentLimitResult({
    required this.isAvailable,
    required this.availableAmounts,
    required this.phoneNumber,
    this.activeAt,
  });

  final String phoneNumber;
  final bool isAvailable;
  final DateTime? activeAt;
  final Set<int> availableAmounts;

  factory PhonePaymentLimitResult.available({
    required String phoneNumber,
    Set<int>? availableAmounts,
  }) {
    return PhonePaymentLimitResult(
      isAvailable: true,
      availableAmounts: availableAmounts ?? const {20, 30, 40, 50},
      phoneNumber: phoneNumber,
    );
  }

  factory PhonePaymentLimitResult.blocked(
    DateTime activeAt, {
    Set<int>? availableAmounts,
  }) {
    return PhonePaymentLimitResult(
      isAvailable: false,
      activeAt: activeAt,
      phoneNumber: '',
      availableAmounts: availableAmounts ?? const {50},
    );
  }

  factory PhonePaymentLimitResult.empty() {
    return const PhonePaymentLimitResult(
      isAvailable: false,
      phoneNumber: '',
      availableAmounts: {50},
    );
  }

  bool isAmountAvailable(int amount) => availableAmounts.contains(amount);

  /// True when `amount` falls outside the allowed daily band.
  bool hasDailyLimit(int amount) {
    if (availableAmounts.isEmpty) return true;
    final lo = availableAmounts.first;
    final hi = availableAmounts.last;
    return amount <= lo && !(amount >= lo && amount <= hi);
  }
}
