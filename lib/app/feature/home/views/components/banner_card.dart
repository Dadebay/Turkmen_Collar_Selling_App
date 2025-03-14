import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/product/constants/index.dart';

class BannerCard extends StatelessWidget {
  final String image;
  final String name;
  final String description;

  const BannerCard({
    required this.image,
    required this.name,
    required this.description,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => Get.to(() => BannerProfileView(name, image, description)),
      child: Container(
        margin: context.padding.low,
        width: size.width,
        decoration: BoxDecoration(borderRadius: context.border.lowBorderRadius),
        child: ClipRRect(
          borderRadius: context.border.lowBorderRadius,
          child: CustomWidgets.customImageView(image: image, cover: true, borderRadius: CustomBorderRadius.normalBorderRadius),
        ),
      ),
    );
  }
}

class BannerProfileView extends GetView {
  final String description;
  final String pageName;
  final String image;

  const BannerProfileView(this.pageName, this.image, this.description, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: pageName, showBackButton: true),
      body: Column(
        children: [
          SizedBox(
            height: WidgetSizes.size256.value,
            child: CustomWidgets.customImageView(image: image, cover: true, borderRadius: CustomBorderRadius.lowBorderRadius),
          ),
          Padding(
            padding: context.padding.normal,
            child: Text(
              description,
              style: context.general.textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
