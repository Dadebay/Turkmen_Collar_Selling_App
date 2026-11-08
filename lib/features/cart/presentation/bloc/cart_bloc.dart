import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/cart_repository.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._repository) : super(CartIdle(_repository.getCart())) {
    on<CartLoaded>(_onLoaded);
    on<CartItemAdded>(_onAdded);
    on<CartItemRemoved>(_onRemoved);
    on<CartCleared>(_onCleared);
    on<CartOrderPlaced>(_onOrderPlaced);
  }

  final CartRepository _repository;

  void _onLoaded(CartLoaded event, Emitter<CartState> emit) {
    emit(CartIdle(_repository.getCart()));
  }

  Future<void> _onAdded(CartItemAdded event, Emitter<CartState> emit) async {
    await _repository.addItem(event.item);
    emit(CartIdle(_repository.getCart()));
  }

  Future<void> _onRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    await _repository.removeItem(event.productId);
    emit(CartIdle(_repository.getCart()));
  }

  Future<void> _onCleared(CartCleared event, Emitter<CartState> emit) async {
    await _repository.clearCart();
    emit(CartIdle(_repository.getCart()));
  }

  Future<void> _onOrderPlaced(
    CartOrderPlaced event,
    Emitter<CartState> emit,
  ) async {
    final items = _repository.getCart();
    emit(CartOrdering(items));
    final result = await _repository.placeOrder(
      userName: event.userName,
      address: event.address,
      city: event.city,
      note: event.note,
      phone: event.phone,
    );
    result.when(
      success: (_) async {
        await _repository.clearCart();
        emit(const CartOrderSuccess());
        // Reset to CartIdle so future cart screens don't get stuck reading
        // CartOrderSuccess (which has no items).
        emit(CartIdle(_repository.getCart()));
      },
      failure: (f) => emit(CartOrderError(f.message, items)),
    );
  }
}
