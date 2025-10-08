import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kartal/kartal.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yaka2/app/product/constants/color_constants.dart';
import 'package:yaka2/app/product/constants/string_constants.dart';

import '../sizes/widget_sizes.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: ColorConstants.greyColor,
        highlightColor: Colors.white,
        child: Text(
          StringConstants.appName.toUpperCase(),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}

enum LoaderType { machine, collar, banner }

class CardsLoading extends StatelessWidget {
  final LoaderType loaderType;

  const CardsLoading({required this.loaderType, super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WidgetSizes.size220.value,
      child: ListView.builder(
        itemCount: 10,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) {
          if (loaderType == LoaderType.collar) {
            return _collarLoading(context);
          } else if (loaderType == LoaderType.machine) {
            return _machineLoading(context);
          } else {
            return _bannerLoading(context);
          }
        },
      ),
    );
  }

  Container _bannerLoading(BuildContext context) {
    return Container(
      margin: context.padding.normal,
      width: Get.size.width - 30,
      decoration: BoxDecoration(borderRadius: context.border.normalBorderRadius, color: ColorConstants.greyColor.withOpacity(.2)),
      child: Loading(),
    );
  }

  Container _collarLoading(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: context.border.lowBorderRadius, color: ColorConstants.greyColor.withOpacity(.2)),
      width: WidgetSizes.size180.value,
      margin: const EdgeInsets.only(left: 15, bottom: 5),
      child: Loading(),
    );
  }

  Container _machineLoading(BuildContext context) {
    return Container(
      width: Get.size.width / 1.2,
      margin: context.padding.onlyLeftNormal,
      decoration: BoxDecoration(borderRadius: context.border.normalBorderRadius, color: ColorConstants.greyColor.withOpacity(.2)),
      child: Loading(),
    );
  }
}
