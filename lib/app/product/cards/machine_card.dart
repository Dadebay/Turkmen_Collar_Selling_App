import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/product_profil/views/product_profil_view.dart';
import 'package:yaka2/app/product/buttons/add_cart_button.dart';

import '../constants/index.dart';

// ignore: must_be_immutable
class MachineCard extends StatelessWidget {
  final ProductModel productModel;

  MachineCard({
    required this.productModel,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ProductProfilView(product: productModel)),
      child: Container(
        width: Get.size.width / 1.2,
        margin: context.padding.normal.copyWith(top: 5, right: 0),
        decoration: BoxDecoration(
          color: ColorConstants.whiteColor,
          borderRadius: context.border.normalBorderRadius,
          border: Border.all(color: ColorConstants.primaryColor.withOpacity(.3)),
          boxShadow: [BoxShadow(color: ColorConstants.greyColor.withOpacity(.3), blurRadius: 2, spreadRadius: 1)],
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
                      style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    CustomWidgets.showProductsPrice(context: context, makeBigger: true, price: productModel.price),
                    Text(
                      productModel.createdAt,
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      style: context.general.textTheme.bodyLarge!.copyWith(fontSize: 18, color: ColorConstants.greyColor.withOpacity(.5)),
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
                color: ColorConstants.whiteColor,
                border: Border.all(color: ColorConstants.primaryColor.withOpacity(.3)),
              ),
              child: ClipRRect(
                borderRadius: CustomBorderRadius.normalBorderRadius,
                child: CustomWidgets.customImageView(image: productModel.image, cover: true, borderRadius: CustomBorderRadius.normalBorderRadius),
              ),
            ),
          ),
          Positioned(bottom: 10, right: 10, child: CustomWidgets.appLogoMini()),
        ],
      ),
    );
  }
}
