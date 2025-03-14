// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/machines_service.dart';
import 'package:yaka2/app/feature/product_profil/views/photo_view.dart';
import 'package:yaka2/app/product/buttons/add_cart_button.dart';
import 'package:yaka2/app/product/constants/index.dart';
import 'package:yaka2/app/product/custom_widgets/custom_functions.dart';

import '../../home/models/clothes_model.dart';
import '../controllers/product_profil_controller.dart';

class MachinesProductProfil extends GetView<ProductProfilController> {
  final ProductProfilController _productProfilController = Get.put(ProductProfilController());

  final ProductModel productModel;

  MachinesProductProfil({
    required this.productModel,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AddCartButton(productProfilDesign: true, productModel: productModel),
      body: FutureBuilder<DressesModelByID>(
        future: MachineService().getMachineByID(productModel.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          } else if (snapshot.hasError) {
            return ErrorState(
              onTap: () {
                MachineService().getMachineByID(productModel.id);
              },
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [appBar(images: snapshot.data!.images, context: context)];
            },
            body: ListView(
              padding: const EdgeInsets.only(top: 20, left: 15, right: 15),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      snapshot.data!.name!,
                      style: const TextStyle(
                        color: ColorConstants.blackColor, //fontFamily: normsProMedium,
                        fontSize: 24,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${CustomFunctions.findPrice(snapshot.data!.price.toString())}',
                          style: const TextStyle(
                            color: ColorConstants.redColor,
                            fontSize: 22,
                            //fontFamily: normProBold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 6, top: 7),
                          child: Text(
                            ' TMT',
                            style: TextStyle(
                              color: ColorConstants.redColor,
                              fontSize: 12,
                              //fontFamily: normProBold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 10),
                  child: Text(
                    'data'.tr,
                    style: const TextStyle(
                      color: ColorConstants.blackColor, //fontFamily: normsProMedium,
                      fontSize: 20,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: twoText(name1: 'data3', name2: '${snapshot.data!.views}'),
                ),
                Divider(
                  thickness: 1,
                  color: ColorConstants.greyColor,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: twoText(name1: 'createdAt'.tr, name2: '${snapshot.data!.createdAt}'),
                ),
                Divider(
                  thickness: 1,
                  color: ColorConstants.greyColor,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 10),
                  child: Text(
                    'data5'.tr,
                    style: const TextStyle(
                      color: ColorConstants.blackColor, //fontFamily: normsProMedium,
                      fontSize: 20,
                    ),
                  ),
                ),
                Text(
                  snapshot.data!.description!,
                  style: const TextStyle(fontSize: 18, color: ColorConstants.blackColor),
                ),
                const SizedBox(
                  height: 200,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AnimatedContainer dot(int index) {
    return AnimatedContainer(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
      height: 16,
      width: 18,
      decoration: BoxDecoration(
        color: _productProfilController.imageDotIndex.value == index ? ColorConstants.primaryColor : ColorConstants.greyColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Padding twoText({required String name1, required String name2}) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name1.tr,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: ColorConstants.greyColor,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              name2.tr,
              maxLines: 2,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: ColorConstants.blackColor,
                fontSize: 18,
                //fontFamily: normsProMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar appBar({required List? images, required BuildContext context}) {
    return SliverAppBar(
      expandedHeight: 400,
      floating: true,
      pinned: false,
      automaticallyImplyLeading: false,
      backgroundColor: ColorConstants.greyColor,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Get.back();
        },
        child: Container(
          margin: const EdgeInsets.only(top: 4, bottom: 4, left: 8),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: context.border.normalBorderRadius,
            color: ColorConstants.whiteColor,
          ),
          child: const Icon(
            IconlyLight.arrowLeftCircle,
            size: 30,
            color: ColorConstants.blackColor,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            // Share.share(image, subject: appName);
          },
          child: Container(
            margin: const EdgeInsets.only(top: 4, bottom: 4, right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: context.border.normalBorderRadius,
              color: ColorConstants.whiteColor,
            ),
            child: Image.asset(
              IconConstants.shareIcon,
              width: 24,
              height: 24,
              color: ColorConstants.blackColor,
            ),
          ),
        ),
      ],
      flexibleSpace: Container(
        color: ColorConstants.greyColor,
        margin: const EdgeInsets.only(top: 30),
        child: CarouselSlider.builder(
          itemCount: images!.length,
          itemBuilder: (context, index, count) {
            return GestureDetector(
              onTap: () {
                Get.to(
                  () => PhotoViewPage(
                    image: images[index],
                    networkImage: true,
                  ),
                );
              },
              child: CachedNetworkImage(
                fadeInCurve: Curves.ease,
                imageUrl: images[index],
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                placeholder: (context, url) => Loading(),
                errorWidget: (context, url, error) => NoImage(),
              ),
            );
          },
          options: CarouselOptions(
            onPageChanged: (index, CarouselPageChangedReason a) {
              _productProfilController.imageDotIndex.value = index;
            },
            viewportFraction: 1.0,
            autoPlay: true,
            height: Get.size.height,
            aspectRatio: 4 / 2,
            scrollPhysics: const BouncingScrollPhysics(),
            autoPlayCurve: Curves.fastLinearToSlowEaseIn,
            autoPlayAnimationDuration: const Duration(milliseconds: 2000),
          ),
        ),
      ),
    );
  }
}
