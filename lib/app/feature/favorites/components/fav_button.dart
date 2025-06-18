import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/auth/services/auth_service.dart';
import 'package:yaka2/app/feature/auth/views/user_login_view.dart';
import 'package:yaka2/app/feature/favorites/controllers/favorites_controller.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/constants/index.dart';

class FavButton extends StatefulWidget {
  final int id;
  final bool isCollar;
  final String name;
  final ProductModel? product;
  final bool? changeBackColor;

  const FavButton({
    required this.isCollar,
    required this.id,
    required this.name,
    this.product,
    this.changeBackColor,
    super.key,
  });

  @override
  State<FavButton> createState() => _FavButtonState();
}

class _FavButtonState extends State<FavButton> {
  final FavoritesController favoritesController = Get.find<FavoritesController>();

  Future<void> _toggleFavorite() async {
    final token = await Auth().getToken();
    if (token == null || token.isEmpty) {
      showSnackBar(
        'loginError'.tr,
        'loginErrorSubtitle1'.tr,
        ColorConstants.redColor,
      );
      await Get.to(() => UserLoginView());
      return;
    }

    bool currentlyFavorite;
    if (widget.isCollar) {
      currentlyFavorite = favoritesController.favCollarListIds.any((element) => element['id'] == widget.id);
    } else {
      currentlyFavorite = favoritesController.favProductListIds.any((element) => element['id'] == widget.id);
    }
    log('FavButton (id=${widget.id}) Toggling. Currently favorite: $currentlyFavorite');

    try {
      if (currentlyFavorite) {
        await favoritesController.removeFavorite(id: widget.id, isCollar: widget.isCollar);
      } else {
        await favoritesController.addFavorite(
          id: widget.id,
          name: widget.name,
          isCollar: widget.isCollar,
          product: widget.product,
        );
      }
    } catch (e) {
      log('FavButton (id=${widget.id}) Error toggling favorite: $e');
      showSnackBar('error'.tr, 'operationFailed'.tr, ColorConstants.redColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool isFavorite;
      List<dynamic> checkedList;
      final String type = widget.isCollar ? 'COLLAR' : 'PRODUCT';

      if (widget.isCollar) {
        checkedList = favoritesController.favCollarListIds;
        isFavorite = checkedList.any((element) => element is Map && element['id'] == widget.id);
      } else {
        checkedList = favoritesController.favProductListIds;
        isFavorite = checkedList.any((element) => element is Map && element['id'] == widget.id);
      }

      final logListContent = checkedList.take(10).toList();
      log('FavButton build: id=${widget.id}, type=$type, isFavoriteResult=$isFavorite, checkedListLength=${checkedList.length}, listContentSample=$logListContent');

      final bool usePrimaryBackground = widget.changeBackColor == true;
      final Color backgroundColor = usePrimaryBackground ? ColorConstants.primaryColor : ColorConstants.whiteColor;
      final Color iconColor;

      if (isFavorite) {
        iconColor = ColorConstants.redColor;
      } else {
        iconColor = usePrimaryBackground ? ColorConstants.whiteColor : ColorConstants.blackColor;
      }

      return GestureDetector(
        onTap: _toggleFavorite,
        child: Container(
          padding: context.padding.low,
          decoration: BoxDecoration(
            borderRadius: CustomBorderRadius.normalBorderRadius,
            color: backgroundColor,
            boxShadow: [
              if (!usePrimaryBackground)
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Icon(
            isFavorite ? IconlyBold.heart : IconlyLight.heart,
            color: iconColor,
            size: 20,
          ),
        ),
      );
    });
  }
}
