part of 'balance_bloc.dart';

sealed class BalanceState {
  const BalanceState();
}

final class BalanceInitial extends BalanceState {
  const BalanceInitial();
}

final class BalanceLoaded extends BalanceState {
  const BalanceLoaded(this.balance);
  final double balance;
}

final class BalanceError extends BalanceState {
  const BalanceError(this.message);
  final String message;
}
