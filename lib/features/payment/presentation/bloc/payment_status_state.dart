part of 'payment_status_bloc.dart';

sealed class PaymentStatusState {
  const PaymentStatusState();

  /// Convenience accessor. Safe default: payments enabled when the state hasn't
  /// loaded yet.
  bool get isDisabled => switch (this) {
    PaymentStatusLoaded(:final isDisabled) => isDisabled,
    _ => false,
  };

  bool get isEnabled => !isDisabled;
}

final class PaymentStatusInitial extends PaymentStatusState {
  const PaymentStatusInitial();
}

final class PaymentStatusLoaded extends PaymentStatusState {
  const PaymentStatusLoaded({required this.isDisabled});

  @override
  // ignore: overridden_fields
  final bool isDisabled;
}
