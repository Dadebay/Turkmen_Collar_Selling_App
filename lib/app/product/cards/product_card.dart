// ignore_for_file: always_put_required_named_parameters_first

import 'package:get/get.dart';
import 'package:yaka2/app/feature/favorites/components/fav_button.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/buttons/add_cart_button.dart';
import 'package:yaka2/app/product/buttons/download_button.dart';

import '../../feature/product_profil/views/product_profil_view.dart';
import '../constants/index.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool? hideCartButton;
  const ProductCard({
    super.key,
    required this.product,
    this.hideCartButton,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductProfilView(product: product));
      },
      child: Container(
        width: WidgetSizes.size180.value,
        margin: context.padding.low,
        decoration: BoxDecoration(
          color: ColorConstants.whiteColor,
          border: Border.all(color: ColorConstants.primaryColor.withOpacity(.2)),
          borderRadius: CustomBorderRadius.normalBorderRadius,
          boxShadow: [
            BoxShadow(color: ColorConstants.greyColor.withOpacity(.3), spreadRadius: 3, blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: CustomWidgets.customImageView(image: product.image, cover: true, borderRadius: CustomBorderRadius.normalBorderRadius)),
                  Positioned(top: 10, right: 10, child: FavButton(isCollar: product.downloadable, id: product.id, name: product.name)),
                  Positioned(bottom: 0, right: 0, child: CustomWidgets.appLogoMini()),
                ],
              ),
            ),
            Padding(
              padding: context.padding.low,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomWidgets.productCardNameAndPrice(context: context, name: product.name, price: product.price),
                  product.downloadable
                      ? DownloadButton(
                          productModel: product,
                          makeBigger: false,
                        )
                      : hideCartButton == true
                          ? Text('quantity'.tr + ': ${product.quantity}', style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, fontSize: 16))
                          : AddCartButton(productModel: product, productProfilDesign: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
