import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/auth/services/auth_service.dart';
import 'package:yaka2/app/feature/auth/views/user_login_view.dart';
import 'package:yaka2/app/product/cards/cart_card.dart';
import 'package:yaka2/app/product/empty_state/empty_cart.dart';

import '../../../product/constants/index.dart';
import '../controllers/cart_controller.dart';
import 'order_page.dart';

class CartView extends GetView<CartController> {
  final CartController cartController = Get.put(CartController());

  CartView({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          cartController.cartList.isEmpty
              ? EmptyCart()
              : Expanded(
                  child: ListView.builder(
                    itemCount: cartController.cartList.length,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return CardCart(
                        productModel: cartController.cartList[index],
                      );
                    },
                  ),
                ),
          orderDetail(context),
        ],
      );
    });
  }

  Container orderDetail(BuildContext context) {
    final double sum = 0;
    // for (var element in cartController.cartList) {
    // double a = double.parse(element['price']);
    // a *= element['quantity'];
    // sum += a;
    // }
    return Container(
      color: ColorConstants.whiteColor,
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(
            color: ColorConstants.primaryColor,
            thickness: 1,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'countProducts'.tr,
                  style: const TextStyle(
                    //fontFamily: normProBold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  cartController.cartList.length.toString(),
                  style: const TextStyle(
                    //fontFamily: normProBold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 15, top: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'priceProduct'.tr,
                  style: const TextStyle(
                    //fontFamily: normProBold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${sum.toStringAsFixed(2)} TMT',
                  style: const TextStyle(
                    //fontFamily: normProBold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = await Auth().getToken();
              if (token == null || token == '') {
                showSnackBar('loginError', 'loginErrorSubtitle', ColorConstants.redColor);
                await Get.to(() => UserLoginView());
              } else {
                if (cartController.cartList.isNotEmpty) {
                  await Get.to(() => const OrderPage());
                } else {
                  showSnackBar('emptyCart', 'emptyCartSubtitle', ColorConstants.redColor);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorConstants.primaryColor, shape: RoundedRectangleBorder(borderRadius: context.border.normalBorderRadius), padding: const EdgeInsets.symmetric(vertical: 15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'orderProducts'.tr,
                  style: const TextStyle(
                    color: ColorConstants.whiteColor,
                  ),
                  //fontFamily: normsProMedium, fontSize: 19),
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    left: 10,
                  ),
                  child: Icon(
                    IconlyBroken.arrowRightCircle,
                    color: ColorConstants.whiteColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
