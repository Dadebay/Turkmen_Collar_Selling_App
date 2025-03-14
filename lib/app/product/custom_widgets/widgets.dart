import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/product/custom_widgets/custom_functions.dart';
import 'package:yaka2/app/product/utils/packages_index.dart';

class CustomWidgets {
  static Widget customImageView({required String image, required bool cover, required BorderRadius borderRadius}) {
    return CachedNetworkImage(
      fadeInCurve: Curves.ease,
      imageUrl: image,
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          // lowBorderRadius ? CustomBorderRadius.lowBorderRadius : CustomBorderRadius.normalBorderRadius,
          image: DecorationImage(
            image: imageProvider,
            fit: cover ? BoxFit.cover : null,
          ),
        ),
      ),
      placeholder: (context, url) => Loading(),
      errorWidget: (context, url, error) => NoImage(),
    );
  }

  static Widget appLogoMini() {
    return Image.asset(
      IconConstants.logo1,
      width: 50,
      height: 20,
    );
  }

  static Widget productCardNameAndPrice({required BuildContext context, required String name, required String price}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        showProductsPrice(context: context, makeBigger: false, price: price),
        Padding(
          padding: context.padding.onlyBottomLow,
          child: Text(
            name,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.blackColor, fontSize: 16),
          ),
        ),
      ],
    );
  }

  static Widget showProductsPrice({required BuildContext context, required bool makeBigger, required String price}) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: CustomFunctions.findPrice(price),
            style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.primaryColor, fontSize: makeBigger ? 22 : 18),
          ),
          TextSpan(
            text: ' TMT',
            style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.primaryColor, fontSize: makeBigger ? 14 : 11),
          ),
        ],
      ),
    );
  }

  static Widget listViewBuilderName({required String text, required BuildContext context, required bool showIcon, required Function() onTap}) {
    return Padding(
      padding: context.padding.normal,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text.tr,
              style: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            if (showIcon)
              const Icon(
                IconlyLight.arrowRightCircle,
                color: ColorConstants.blackColor,
              ),
          ],
        ),
      ),
    );
  }
}

SnackbarController showSnackBar(String title, String subtitle, Color color) {
  SnackbarController.cancelAllSnackbars();
  return Get.snackbar(
    title,
    subtitle,
    snackStyle: SnackStyle.FLOATING,
    titleText: title == ''
        ? const SizedBox.shrink()
        : Text(
            title.tr,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: ColorConstants.whiteColor,
            ),
          ),
    messageText: Text(
      subtitle.tr,
      style: TextStyle(
        fontSize: 16,
        color: ColorConstants.whiteColor,
      ),
    ),
    snackPosition: SnackPosition.TOP,
    backgroundColor: color,
    borderRadius: 20.0,
    animationDuration: const Duration(milliseconds: 500),
    margin: const EdgeInsets.all(8),
  );
}

CustomFooter footer() {
  return CustomFooter(
    builder: (BuildContext context, LoadStatus? mode) {
      Widget body;
      if (mode == LoadStatus.idle) {
        body = const Text('Garasyn...');
      } else if (mode == LoadStatus.loading) {
        body = const CircularProgressIndicator(
          color: ColorConstants.primaryColor,
        );
      } else if (mode == LoadStatus.failed) {
        body = const Text('Load Failed!Click retry!');
      } else if (mode == LoadStatus.canLoading) {
        body = const Text('');
      } else {
        body = const Text('No more Data');
      }
      return SizedBox(
        height: 55.0,
        child: Center(child: body),
      );
    },
  );
}

Container customIcon(String iconNmae) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: ColorConstants.primaryColor.withOpacity(0.8), borderRadius: CustomBorderRadius.normalBorderRadius),
    child: Image.asset(
      iconNmae,
      width: 24,
      height: 24,
      color: ColorConstants.whiteColor,
    ),
  );
}

Padding textpart(String name, bool value) {
  return Padding(
    padding: EdgeInsets.only(left: 8, top: value ? 15 : 30),
    child: Text(
      name.tr,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: const TextStyle(
        fontSize: 18, color: ColorConstants.blackColor, //fontFamily: normsProMedium
      ),
    ),
  );
}

Container divider() {
  return Container(
    // color: ColorConstants.whiteColor,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Divider(
      color: ColorConstants.primaryColor.withOpacity(0.4),
      thickness: 2,
    ),
  );
}
