part of 'cart_bloc.dart';

sealed class CartState {
  const CartState();
}

final class CartIdle extends CartState {
  const CartIdle(this.items);
  final List<CartItemEntity> items;

  int get totalQuantity => items.fold<int>(0, (sum, i) => sum + i.quantity);

  double get totalPrice => items.fold<double>(
    0,
    (sum, i) => sum + (double.tryParse(i.price) ?? 0) * i.quantity,
  );
}

final class CartOrdering extends CartState {
  const CartOrdering(this.items);
  final List<CartItemEntity> items;
}

final class CartOrderSuccess extends CartState {
  const CartOrderSuccess();
}

final class CartOrderError extends CartState {
  const CartOrderError(this.message, this.items);
  final String message;
  final List<CartItemEntity> items;
}
