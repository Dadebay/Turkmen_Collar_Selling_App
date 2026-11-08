import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

import 'package:go_router/go_router.dart';

import '../../../features/favorites/presentation/widgets/fav_button.dart';
import '../../../features/home/domain/entities/product_entity.dart';
import '../../constants/border_radius_constants.dart';
import '../../constants/widget_sizes.dart';
import '../../l10n/app_translations.dart';
import '../../router/app_router.dart';
import '../../theme/color_constants.dart';
import '../../theme/context_extensions.dart';
import '../custom_widgets.dart';
import '../buttons/add_cart_button.dart';
import '../buttons/download_button.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final bool? hideCartButton;
  final EdgeInsetsGeometry? margin;
  const ProductCard({
    required this.product,
    super.key,
    this.hideCartButton,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.productDetailPath(product.id), extra: product),
      child: Container(
        width: WidgetSizes.size180.value,
        margin: margin ?? context.padding.low,
        decoration: BoxDecoration(
          color: AppPalette.of(context).surface,
          border: Border.all(
            color: ColorConstants.primaryColor.withOpacity(.2),
          ),
          borderRadius: CustomBorderRadius.normalBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomWidgets.customImageView(
                      image: product.image,
                      cover: true,
                      borderRadius: CustomBorderRadius.normalBorderRadius,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FavButton(
                      isCollar: product.downloadable,
                      id: product.id,
                      name: product.name,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CustomWidgets.appLogoMini(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: context.padding.low,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomWidgets.productCardNameAndPrice(
                    context: context,
                    name: product.name,
                    price: product.price,
                  ),
                  product.downloadable
                      ? DownloadButton(productModel: product, makeBigger: false)
                      : hideCartButton == true
                      ? Text(
                          '${'quantity'.tr}: ${product.quantity}',
                          style: context.general.textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : AddCartButton(
                          productModel: product,
                          productProfilDesign: false,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
