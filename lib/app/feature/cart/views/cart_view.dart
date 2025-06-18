import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/auth/services/auth_service.dart';
import 'package:yaka2/app/feature/auth/views/user_login_view.dart';
import 'package:yaka2/app/product/cards/cart_card.dart';
import 'package:yaka2/app/product/custom_widgets/custom_functions.dart';
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
    double sum = 0;
    cartController.cartList.forEach((element) {
      sum += double.parse(element.price.toString()) * (element.quantity ?? 1);
    });
    return Container(
      color: ColorConstants.whiteColor,
      padding: context.padding.normal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: ColorConstants.primaryColor, thickness: 1),
          Padding(
            padding: context.padding.verticalLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'countProducts'.tr,
                  style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.greyColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  cartController.cartList.length.toString(),
                  style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.blackColor, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: context.padding.verticalNormal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'priceProduct'.tr,
                  style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.greyColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  CustomFunctions.findPrice(sum.toString()) + ' TMT',
                  style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.blackColor, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          AgreeButton(
            onTap: () async {
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
            text: 'orderProducts',
          ),
        ],
      ),
    );
  }
}
