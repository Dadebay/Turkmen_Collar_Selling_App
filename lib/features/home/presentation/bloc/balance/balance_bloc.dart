import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/result/result.dart';
import '../../../domain/repositories/home_repository.dart';

part 'balance_event.dart';
part 'balance_state.dart';

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  BalanceBloc(this._repository)
    : super(
        // Seed from the last known balance (cached by the splash token
        // validation / a previous session) so the wallet shows a value
        // immediately instead of waiting for the network.
        _repository.cachedBalance != null
            ? BalanceLoaded(_repository.cachedBalance!)
            : const BalanceInitial(),
      ) {
    on<BalanceFetchRequested>(_onFetch);
  }

  final HomeRepository _repository;

  Future<void> _onFetch(
    BalanceFetchRequested event,
    Emitter<BalanceState> emit,
  ) async {
    final result = await _repository.getUserBalance(
      forceRefresh: event.forceRefresh,
    );
    result.when(
      success: (balance) => emit(BalanceLoaded(balance)),
      failure: (f) => emit(BalanceError(f.message)),
    );
  }
}
