import 'dart:convert';

import '../../../../core/storage/local_storage.dart';
import '../models/cart_item_model.dart';

class CartLocalDataSource {
  const CartLocalDataSource(this._storage);
  final LocalStorage _storage;

  List<CartItemModel> getCart() {
    final json = _storage.cartJson;
    if (json == null) {
      return [];
    }
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CartItemModel.fromJson(e as Map<dynamic, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCart(List<CartItemModel> items) async {
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await _storage.saveCartJson(json);
  }
}
