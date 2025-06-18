import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/buttons/add_cart_button.dart';
import 'package:yaka2/app/product/constants/index.dart';

class CardCart extends StatelessWidget {
  final ProductModel productModel;
  const CardCart({
    required this.productModel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: WidgetSizes.size180.value,
      padding: context.padding.normal,
      margin: context.padding.normal.copyWith(bottom: 0),
      decoration: BoxDecoration(
        borderRadius: context.border.normalBorderRadius,
        color: ColorConstants.whiteColor,
        boxShadow: [BoxShadow(color: ColorConstants.greyColor.withOpacity(.3), spreadRadius: 3, blurRadius: 3)],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: context.padding.onlyRightNormal,
              width: Get.size.width,
              height: Get.size.height,
              decoration: BoxDecoration(borderRadius: context.border.lowBorderRadius, color: ColorConstants.whiteColor, border: Border.all(color: ColorConstants.blackColor.withOpacity(.4))),
              child: ClipRRect(
                borderRadius: context.border.lowBorderRadius,
                child: CustomWidgets.customImageView(image: productModel.image, cover: true, borderRadius: context.border.lowBorderRadius),
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
                  style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.blackColor, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                CustomWidgets.showProductsPrice(context: context, makeBigger: true, price: productModel.price.toString()),
                Text(
                  productModel.createdAt,
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.greyColor, fontSize: 18),
                ),
                AddCartButton(
                  productModel: productModel,
                  productProfilDesign: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
