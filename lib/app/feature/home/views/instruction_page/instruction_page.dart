import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/views/instruction_page/video_player_page.dart';
import 'package:yaka2/app/feature/payment/controllers/payment_status_controller.dart';
import 'package:yaka2/app/feature/product_profil/views/photo_view.dart';
import 'package:yaka2/app/product/constants/index.dart';

class InstructionPage extends StatelessWidget {
  InstructionPage({Key? key}) : super(key: key);
  final List<Map<String, String>> videos1 = const [
    {'title': 'videoTitle1', 'path': 'assets/videos/1.mp4'},
    {'title': 'videoTitle2', 'path': 'assets/videos/2.mp4'},
    {'title': 'videoTitle4', 'path': 'assets/videos/3.mp4'},
    {'title': 'videoTitle3', 'path': 'assets/videos/4.mp4'},
  ];
  final PaymentStatusController paymentStatusController = Get.find();
  final List<Map<String, String>> videos2 = const [
    {'title': 'videoTitle1', 'path': 'assets/videos/1.mp4'},
    // {'title': 'videoTitle2', 'path': 'assets/videos/2.mp4'},
    // {'title': 'videoTitle4', 'path': 'assets/videos/3.mp4'},
    // {'title': 'videoTitle3', 'path': 'assets/videos/4.mp4'},
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(title: 'insPage', showBackButton: true),
        body: paymentStatusController.isPaymentDisabled.value == true
            ? _tabbarPage2(videos2)
            : Column(
                children: [
                  Container(
                    color: ColorConstants.primaryColor,
                    child: TabBar(
                      labelColor: ColorConstants.whiteColor,
                      indicatorColor: ColorConstants.whiteColor,
                      labelStyle: context.general.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                      unselectedLabelStyle: context.general.textTheme.titleMedium!.copyWith(fontSize: 18),
                      dividerColor: ColorConstants.whiteColor,
                      unselectedLabelColor: ColorConstants.whiteColor.withOpacity(.8),
                      isScrollable: false,
                      tabs: [
                        Tab(text: 'video_tabbar'.tr),
                        Tab(text: 'image_tabbar'.tr),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _tabbarPage2(videos1),
                        _tabbarPage1(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  ListView _tabbarPage2(List<Map<String, String>> videos) {
    return ListView.separated(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return ListTile(
          tileColor: ColorConstants.whiteColor,
          onTap: () {
            Get.to(() => VideoPlayerPage(videoPath: videos[index]['path']!, appBarTitle: videos[index]['title']!));
          },
          title: Text(
            videos[index]['title']!.tr,
            maxLines: 2,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: context.general.textTheme.bodyLarge!.copyWith(fontSize: 18),
          ),
          leading: Text(
            '${index + 1}',
            style: context.general.textTheme.bodyLarge!.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Icon(IconlyLight.play),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: context.padding.horizontalNormal,
          child: Divider(
            color: ColorConstants.blackColor.withOpacity(.1),
          ),
        );
      },
    );
  }

  CarouselSlider _tabbarPage1() {
    return CarouselSlider.builder(
      itemCount: 4,
      itemBuilder: (context, index, count) {
        return GestureDetector(
          onTap: () {
            Get.to(
              () => PhotoViewPage(
                image: 'assets/image/instruction/${index + 1}.png',
                networkImage: false,
              ),
            );
          },
          child: Image.asset(
            'assets/image/instruction/${index + 1}.png',
            fit: BoxFit.contain,
          ),
        );
      },
      options: CarouselOptions(
        onPageChanged: (index, CarouselPageChangedReason a) {},
        height: Get.size.height,
        viewportFraction: 0.8,
        autoPlay: true,
        scrollPhysics: const BouncingScrollPhysics(),
        autoPlayCurve: Curves.fastLinearToSlowEaseIn,
        autoPlayAnimationDuration: const Duration(milliseconds: 2000),
      ),
    );
  }
}
