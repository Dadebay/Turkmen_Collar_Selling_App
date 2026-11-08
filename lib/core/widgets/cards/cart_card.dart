import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

import '../../../features/cart/domain/entities/cart_item_entity.dart';
import '../../../features/home/domain/entities/product_entity.dart';
import '../../constants/widget_sizes.dart';
import '../../theme/context_extensions.dart';
import '../custom_widgets.dart';
import '../buttons/add_cart_button.dart';

class CardCart extends StatelessWidget {
  final CartItemEntity productModel;
  const CardCart({required this.productModel, super.key});

  ProductEntity get _asProduct => ProductEntity(
    id: productModel.id,
    name: productModel.name,
    price: productModel.price,
    image: productModel.image,
    categoryName: productModel.categoryName,
    downloadable: false,
    quantity: productModel.quantity,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: WidgetSizes.size180.value,
      padding: context.padding.normal,
      margin: context.padding.normal.copyWith(bottom: 0),
      decoration: BoxDecoration(
        borderRadius: context.border.normalBorderRadius,
        color: AppPalette.of(context).surface,
        boxShadow: [
          BoxShadow(
            color: AppPalette.of(context).muted.withOpacity(.3),
            spreadRadius: 3,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: context.padding.onlyRightNormal,
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              decoration: BoxDecoration(
                borderRadius: context.border.lowBorderRadius,
                color: AppPalette.of(context).surface,
                border: Border.all(
                  color: AppPalette.of(context).text.withOpacity(.4),
                ),
              ),
              child: ClipRRect(
                borderRadius: context.border.lowBorderRadius,
                child: CustomWidgets.customImageView(
                  image: productModel.image,
                  cover: true,
                  borderRadius: context.border.lowBorderRadius,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  productModel.name,
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  style: context.general.textTheme.bodyLarge!.copyWith(
                    color: AppPalette.of(context).text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                CustomWidgets.showProductsPrice(
                  context: context,
                  makeBigger: false,
                  price: productModel.price,
                ),
                AddCartButton(
                  productModel: _asProduct,
                  productProfilDesign: false,
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
