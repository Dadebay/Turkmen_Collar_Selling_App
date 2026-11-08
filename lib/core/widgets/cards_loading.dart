import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import '../constants/widget_sizes.dart';
import '../theme/context_extensions.dart';
import 'loading.dart';

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
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: AppPalette.of(context).muted.withOpacity(.2),
      ),
      child: const Loading(),
    );
  }

  Container _collarLoading(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: context.border.lowBorderRadius,
        color: AppPalette.of(context).muted.withOpacity(.2),
      ),
      width: WidgetSizes.size180.value,
      margin: const EdgeInsets.only(left: 15, bottom: 5),
      child: const Loading(),
    );
  }

  Container _machineLoading(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width / 1.2,
      margin: context.padding.onlyLeftNormal,
      decoration: BoxDecoration(
        borderRadius: context.border.normalBorderRadius,
        color: AppPalette.of(context).muted.withOpacity(.2),
      ),
      child: const Loading(),
    );
  }
}
