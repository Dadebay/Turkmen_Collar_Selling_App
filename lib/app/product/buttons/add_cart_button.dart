import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:yaka2/app/feature/cart/controllers/cart_controller.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/user_profil/controllers/user_profil_controller.dart';
import 'package:yaka2/app/product/constants/index.dart';

class AddCartButton extends StatefulWidget {
  final ProductModel productModel;
  final bool productProfilDesign;

  const AddCartButton({
    required this.productModel,
    required this.productProfilDesign,
    Key? key,
  }) : super(key: key);

  @override
  State<AddCartButton> createState() => _AddCartButtonState();
}

class _AddCartButtonState extends State<AddCartButton> {
  final CartController cartController = Get.find();
  final UserProfilController userProfilController = Get.find();

  bool get isInCart => cartController.cartList.any((item) => item.id == widget.productModel.id);

  int get quantity =>
      cartController.cartList
          .firstWhere(
            (item) => item.id == widget.productModel.id,
            orElse: () => ProductModel.fromJson({'quantity': 0}),
          )
          .quantity ??
      0;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => quantity > 0
          ? _buildQuantityChanger()
          : widget.productProfilDesign
              ? _addCartButtonProductProfil()
              : _buildAddButton(),
    );
  }

  Widget _addCartButtonProductProfil() {
    return Padding(
      padding: context.padding.normal,
      child: AgreeButton(onTap: () => cartController.addToCart(widget.productModel), text: 'addCart'),
    );
  }

  Widget _buildAddButton() {
    return Row(
      mainAxisAlignment: widget.productProfilDesign ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => cartController.addToCart(widget.productModel),
          child: Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(color: ColorConstants.primaryColor, borderRadius: widget.productProfilDesign ? context.border.normalBorderRadius : context.border.lowBorderRadius),
            child: Icon(IconlyBold.bag, color: ColorConstants.whiteColor),
          ),
        ),
        if (!widget.productProfilDesign)
          GestureDetector(
            onTap: () async {
              await launchUrlString('tel://${userProfilController.phoneNumber.value}');
            },
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(color: ColorConstants.primaryColor.withOpacity(.2), borderRadius: widget.productProfilDesign ? context.border.normalBorderRadius : context.border.lowBorderRadius),
              child: Icon(Icons.call, color: ColorConstants.primaryColor),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityChanger() {
    return Container(
      decoration: BoxDecoration(borderRadius: context.border.normalBorderRadius, color: widget.productProfilDesign ? ColorConstants.primaryColorCard : Colors.transparent),
      margin: widget.productProfilDesign ? context.padding.normal : EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIconButton(
            icon: CupertinoIcons.minus,
            onTap: () => cartController.removeFromCart(widget.productModel.id),
            context: context,
          ),
          Expanded(
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, fontSize: widget.productProfilDesign ? 24 : 20),
            ),
          ),
          _buildIconButton(
            icon: CupertinoIcons.add,
            onTap: () => cartController.addToCart(widget.productModel),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, required BuildContext context}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: widget.productProfilDesign ? context.padding.normal : EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ColorConstants.primaryColor,
          borderRadius: CustomBorderRadius.lowBorderRadius,
        ),
        child: Icon(icon, color: ColorConstants.whiteColor),
      ),
    );
  }
}
