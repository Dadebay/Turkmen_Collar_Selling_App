import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/home_controller.dart';
import 'package:yaka2/app/feature/home/models/banner_model.dart';
import 'package:yaka2/app/feature/home/views/components/banner_card.dart';
import 'package:yaka2/app/product/constants/index.dart';

class BannersView extends GetView {
  final HomeController bannerController = Get.find();
  BannersView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BannerModel>>(
      future: bannerController.getBanners,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CardsLoading(loaderType: LoaderType.banner);
        } else if (snapshot.hasError) {
          return SizedBox.shrink();
        } else if (snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarouselSlider.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index, count) {
                return BannerCard(
                  image: snapshot.data![index].image!,
                  name: snapshot.data![index].title!,
                  description: snapshot.data![index].description!,
                );
              },
              options: CarouselOptions(
                onPageChanged: (index, CarouselPageChangedReason a) {
                  bannerController.bannerDotsIndex.value = index;
                },
                height: Get.size.height / 4,
                viewportFraction: 1.0,
                autoPlay: true,
                scrollPhysics: const BouncingScrollPhysics(),
                autoPlayCurve: Curves.fastLinearToSlowEaseIn,
                autoPlayAnimationDuration: const Duration(milliseconds: 2000),
              ),
            ),
            dots(snapshot.data!.length),
          ],
        );
      },
    );
  }

  SizedBox dots(int length) {
    return SizedBox(
      height: 4,
      width: Get.size.width,
      child: Center(
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: length,
          itemBuilder: (BuildContext context, int index) {
            return Obx(() {
              return dot(index);
            });
          },
        ),
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
        color: bannerController.bannerDotsIndex.value == index ? ColorConstants.primaryColor : ColorConstants.greyColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
