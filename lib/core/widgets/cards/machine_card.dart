import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

import 'package:go_router/go_router.dart';

import '../../../features/home/domain/entities/product_entity.dart';
import '../../constants/border_radius_constants.dart';
import '../../router/app_router.dart';
import '../../theme/color_constants.dart';
import '../../theme/context_extensions.dart';
import '../custom_widgets.dart';
import '../buttons/add_cart_button.dart';

class MachineCard extends StatelessWidget {
  final ProductEntity productModel;

  const MachineCard({required this.productModel, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.productDetailPath(productModel.id),
        extra: productModel,
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width / 1.2,
        margin: context.padding.normal.copyWith(top: 5, right: 0),
        decoration: BoxDecoration(
          color: AppPalette.of(context).surface,
          borderRadius: context.border.normalBorderRadius,
          border: Border.all(
            color: ColorConstants.primaryColor.withOpacity(.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppPalette.of(context).muted.withOpacity(.3),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            _image(context),
            Expanded(
              flex: 3,
              child: Padding(
                padding: context.padding.low,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      productModel.name,
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: context.general.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    CustomWidgets.showProductsPrice(
                      context: context,
                      makeBigger: true,
                      price: productModel.price,
                    ),
                    Text(
                      productModel.createdAt,
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      style: context.general.textTheme.bodyLarge!.copyWith(
                        fontSize: 18,
                        color: AppPalette.of(context).muted.withOpacity(.5),
                      ),
                    ),
                    AddCartButton(
                      productModel: productModel,
                      productProfilDesign: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Expanded _image(BuildContext context) {
    return Expanded(
      flex: 3,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: context.padding.low,
              decoration: BoxDecoration(
                borderRadius: CustomBorderRadius.normalBorderRadius,
                color: AppPalette.of(context).surface,
                border: Border.all(
                  color: ColorConstants.primaryColor.withOpacity(.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: CustomBorderRadius.normalBorderRadius,
                child: CustomWidgets.customImageView(
                  image: productModel.image,
                  cover: true,
                  borderRadius: CustomBorderRadius.normalBorderRadius,
                ),
              ),
            ),
          ),
          Positioned(bottom: 10, right: 10, child: CustomWidgets.appLogoMini()),
        ],
      ),
    );
  }
}
