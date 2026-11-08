part of 'payment_status_bloc.dart';

sealed class PaymentStatusEvent {
  const PaymentStatusEvent();
}

final class PaymentStatusFetchRequested extends PaymentStatusEvent {
  const PaymentStatusFetchRequested();
}

final class PaymentStatusRefreshRequested extends PaymentStatusEvent {
  const PaymentStatusRefreshRequested();
}
