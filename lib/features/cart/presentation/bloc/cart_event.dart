part of 'cart_bloc.dart';

sealed class CartEvent {
  const CartEvent();
}

final class CartLoaded extends CartEvent {
  const CartLoaded();
}

final class CartItemAdded extends CartEvent {
  const CartItemAdded(this.item);
  final CartItemEntity item;
}

final class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);
  final int productId;
}

final class CartCleared extends CartEvent {
  const CartCleared();
}

final class CartOrderPlaced extends CartEvent {
  const CartOrderPlaced({
    required this.userName,
    required this.address,
    required this.city,
    required this.note,
    required this.phone,
  });
  final String userName;
  final String address;
  final String city;
  final String note;
  final String phone;
}
