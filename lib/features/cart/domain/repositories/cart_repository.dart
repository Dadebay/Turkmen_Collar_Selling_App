import '../../../../core/result/result.dart';
import '../entities/cart_item_entity.dart';

abstract interface class CartRepository {
  List<CartItemEntity> getCart();
  Future<void> addItem(CartItemEntity item);
  Future<void> removeItem(int productId);
  Future<void> clearCart();
  Future<Result<void>> placeOrder({
    required String userName,
    required String address,
    required String city,
    required String note,
    required String phone,
  });
}
