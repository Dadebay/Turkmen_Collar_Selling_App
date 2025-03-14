import '../constants/index.dart';

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
                        color: ColorConstants.greyColor.withOpacity(.2),
                        borderRadius: CustomBorderRadius.normalBorderRadius,
                      ),
                      child: Loading(),
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
