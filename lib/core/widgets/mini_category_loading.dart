import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import '../constants/border_radius_constants.dart';
import '../constants/widget_sizes.dart';
import '../theme/context_extensions.dart';
import 'loading.dart';

class MiniCategoryLoading extends StatelessWidget {
  const MiniCategoryLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: 10,
      itemBuilder: (context, index, count) {
        return Column(
          children: List.generate(2, (rowIndex) {
            return Expanded(
              child: Row(
                children: List.generate(2, (colIndex) {
                  return Expanded(
                    child: Container(
                      margin: context.padding.low,
                      decoration: BoxDecoration(
                        color: AppPalette.of(context).muted.withOpacity(.2),
                        borderRadius: CustomBorderRadius.normalBorderRadius,
                      ),
                      child: const Loading(),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
      options: CarouselOptions(
        onPageChanged: (index, CarouselPageChangedReason a) {},
        height: WidgetSizes.size300.value,
        viewportFraction: 1.0,
        autoPlay: true,
        enableInfiniteScroll: true,
        scrollPhysics: const BouncingScrollPhysics(),
        autoPlayCurve: Curves.fastLinearToSlowEaseIn,
        autoPlayAnimationDuration: const Duration(milliseconds: 2000),
      ),
    );
  }
}
