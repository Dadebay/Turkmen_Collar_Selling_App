part of 'balance_bloc.dart';

sealed class BalanceEvent {
  const BalanceEvent();
}

final class BalanceFetchRequested extends BalanceEvent {
  const BalanceFetchRequested({this.forceRefresh = true});

  /// When false, a recently fetched value (e.g. from splash token validation)
  /// is reused instead of hitting the network. Refreshes that must reflect a
  /// server-side change (after a purchase, periodic poll) keep this true.
  final bool forceRefresh;
}
