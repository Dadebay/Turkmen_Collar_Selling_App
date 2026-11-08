// ignore_for_file: always_put_control_body_on_new_line
import 'dart:io';

import 'package:bloc/bloc.dart';

import '../../../../core/result/result.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/datasources/payment_status_remote_data_source.dart';

part 'payment_status_event.dart';
part 'payment_status_state.dart';

class PaymentStatusBloc extends Bloc<PaymentStatusEvent, PaymentStatusState> {
  PaymentStatusBloc({required this.remote, required this.storage})
    : super(_initialFromCache(storage)) {
    on<PaymentStatusFetchRequested>(_onFetchRequested);
    on<PaymentStatusRefreshRequested>(_onRefreshRequested);
  }

  final PaymentStatusRemoteDataSource remote;
  final LocalStorage storage;

  static PaymentStatusState _initialFromCache(LocalStorage storage) {
    final cached = storage.paymentDisabled;
    if (cached == null) return const PaymentStatusInitial();
    return PaymentStatusLoaded(isDisabled: cached);
  }

  Future<void> _onFetchRequested(
    PaymentStatusFetchRequested event,
    Emitter<PaymentStatusState> emit,
  ) async {
    final cached = storage.paymentDisabled;
    if (cached != null) emit(PaymentStatusLoaded(isDisabled: cached));
    await _refresh(emit);
  }

  Future<void> _onRefreshRequested(
    PaymentStatusRefreshRequested event,
    Emitter<PaymentStatusState> emit,
  ) => _refresh(emit);

  Future<void> _refresh(Emitter<PaymentStatusState> emit) async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      await storage.savePaymentDisabled(false);
      emit(PaymentStatusLoaded(isDisabled: false));
      return;
    }
    final result = await remote.fetchPaymentDisabled();
    if (result is Success<bool>) {
      final disabled = result.dataOrThrow;
      await storage.savePaymentDisabled(disabled);
      emit(PaymentStatusLoaded(isDisabled: disabled));
    } else {
      // On error keep whatever the current state holds (cache or initial).
      // Don't downgrade a valid loaded value just because the network blipped.
    }
  }
}
