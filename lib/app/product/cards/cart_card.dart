import 'package:flutter/material.dart';
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
      width: Get.size.width,
      height: Get.size.height / 5,
      margin: const EdgeInsets.only(left: 15, right: 15, top: 15),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          elevation: 1,
          // backgroundColor: Theme.of(context).colorScheme.background,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: context.border.normalBorderRadius),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(12),
                width: Get.size.width,
                height: Get.size.height,
                decoration: BoxDecoration(
                  borderRadius: context.border.lowBorderRadius,
                  color: ColorConstants.whiteColor,
                ),
                child: ClipRRect(
                  borderRadius: context.border.lowBorderRadius,
                  child: CachedNetworkImage(
                    fadeInCurve: Curves.ease,
                    imageUrl: productModel.image,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: context.border.lowBorderRadius,
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    placeholder: (context, url) => Loading(),
                    errorWidget: (context, url, error) => NoImage(),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 10, left: 14, right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      productModel.name,
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ColorConstants.blackColor, fontSize: 19),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            productModel.price,
                            style: const TextStyle(
                              color: ColorConstants.redColor,
                              fontSize: 21,
                              //fontFamily: normProBold,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              ' TMT',
                              style: TextStyle(
                                color: ColorConstants.redColor,
                                fontSize: 12,
                                //fontFamily: normsProMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      productModel.createdAt,
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ColorConstants.greyColor,
                        fontSize: 16,
                        //fontFamily: normProBold,
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
}
