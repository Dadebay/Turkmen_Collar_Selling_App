import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';

class CartController extends GetxController {
  RxList<ProductModel> cartList = <ProductModel>[].obs;
  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    loadCartFromStorage();
  }

  void addToCart(ProductModel product) {
    final int index = cartList.indexWhere((item) => item.id == product.id);
    if (index != -1) {
      cartList[index] = ProductModel.fromJson({
        ...cartList[index].toJson(),
        'quantity': (cartList[index].quantity ?? 0) + 1,
      });
    } else {
      cartList.add(
        ProductModel.fromJson({
          ...product.toJson(),
          'quantity': 1,
        }),
      );
    }
    _saveCartToStorage();
  }

  void removeFromCart(int productId) {
    final int index = cartList.indexWhere((item) => item.id == productId);
    if (index != -1) {
      final int currentQuantity = cartList[index].quantity ?? 1;
      if (currentQuantity > 1) {
        cartList[index] = ProductModel.fromJson({
          ...cartList[index].toJson(),
          'quantity': currentQuantity - 1,
        });
      } else {
        cartList.removeAt(index);
      }
      _saveCartToStorage();
    }
  }

  void clearCart() {
    cartList.clear();
    _saveCartToStorage();
  }

  void loadCartFromStorage() {
    final String? storedCart = storage.read('cartList');
    if (storedCart != null) {
      final List<dynamic> decodedList = jsonDecode(storedCart);
      cartList.value = decodedList.map((item) => ProductModel.fromJson(item)).toList();
    }
  }

  void _saveCartToStorage() {
    final String jsonString = jsonEncode(cartList.map((e) => e.toJson()).toList());
    storage.write('cartList', jsonString);
  }
}
