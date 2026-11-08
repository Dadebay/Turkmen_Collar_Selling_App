import '../../../../core/result/result.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';
import '../datasources/cart_remote_data_source.dart';
import '../models/cart_item_model.dart';

class CartRepositoryImpl implements CartRepository {
  const CartRepositoryImpl({
    required CartLocalDataSource local,
    required CartRemoteDataSource remote,
  }) : _local = local,
       _remote = remote;

  final CartLocalDataSource _local;
  final CartRemoteDataSource _remote;

  @override
  List<CartItemEntity> getCart() =>
      _local.getCart().map((m) => m.toEntity()).toList();

  @override
  Future<void> addItem(CartItemEntity item) async {
    final current = _local.getCart();
    final idx = current.indexWhere((m) => m.id == item.id);
    if (idx != -1) {
      current[idx] = CartItemModel(
        id: current[idx].id,
        name: current[idx].name,
        price: current[idx].price,
        image: current[idx].image,
        quantity: current[idx].quantity + 1,
        categoryName: current[idx].categoryName,
      );
    } else {
      current.add(CartItemModel.fromEntity(item.copyWith(quantity: 1)));
    }
    await _local.saveCart(current);
  }

  @override
  Future<void> removeItem(int productId) async {
    final current = _local.getCart();
    final idx = current.indexWhere((m) => m.id == productId);
    if (idx == -1) {
      return;
    }
    if (current[idx].quantity > 1) {
      current[idx] = CartItemModel(
        id: current[idx].id,
        name: current[idx].name,
        price: current[idx].price,
        image: current[idx].image,
        quantity: current[idx].quantity - 1,
        categoryName: current[idx].categoryName,
      );
    } else {
      current.removeAt(idx);
    }
    await _local.saveCart(current);
  }

  @override
  Future<void> clearCart() => _local.saveCart([]);

  @override
  Future<Result<void>> placeOrder({
    required String userName,
    required String address,
    required String city,
    required String note,
    required String phone,
  }) async {
    final items = _local.getCart();
    final products = items
        .map((i) => {'id': i.id, 'quantity': i.quantity})
        .toList();
    return _remote.placeOrder(
      products: products,
      customerName: userName,
      address: address,
      province: city,
      phone: phone,
      note: note,
    );
  }
}
