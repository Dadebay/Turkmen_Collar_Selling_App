import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/collar_model.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/collars_service.dart';
import 'package:yaka2/app/feature/home/services/dresses_service.dart';
import 'package:yaka2/app/feature/home/views/instruction_page/video_player_page.dart';
import 'package:yaka2/app/product/buttons/download_button.dart';
import 'package:yaka2/app/product/custom_widgets/custom_functions.dart';
import 'package:yaka2/app/product/utils/packages_index.dart';

class ProductProfilView extends StatefulWidget {
  final ProductModel product;
  const ProductProfilView({required this.product, super.key});
  @override
  State<ProductProfilView> createState() => _ProductProfilViewState();
}

class _ProductProfilViewState extends State<ProductProfilView> {
  late Future<ProductModel> future;
  late Future<CollarByIDModel> collar;
  @override
  void initState() {
    super.initState();
    if (widget.product.downloadable) {
      collar = CollarService().getCollarsByID(widget.product.id);
    } else {
      future = DressesService().getDressesByID(widget.product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: widget.product.downloadable ? DownloadButton(productModel: widget.product, makeBigger: true) : AddCartButton(productModel: widget.product, productProfilDesign: true),
      appBar: CustomAppBar(
          title: widget.product.name, showBackButton: true, actionButton: FavButton(changeBackColor: true, name: widget.product.name, id: widget.product.id, isCollar: widget.product.downloadable)),
      body: widget.product.downloadable ? downloadablePage() : orderPage(),
    );
  }

  Widget _carouselImages(List images) {
    print(images);
    final bool hasVideo = widget.product.videoURL != null && widget.product.videoURL!.isNotEmpty;

    return CarouselSlider.builder(
      itemCount: hasVideo ? images.length + 1 : images.length,
      itemBuilder: (context, index, count) {
        if (hasVideo && index == images.length) {
          return _videoPreview(images, context);
        }
        return GestureDetector(
          onTap: () => Get.to(() => PhotoViewPage(image: images[index], networkImage: true)),
          child: CustomWidgets.customImageView(image: images[index], cover: true, borderRadius: BorderRadius.zero),
        );
      },
      options: CarouselOptions(
        onPageChanged: (index, CarouselPageChangedReason a) {},
        viewportFraction: 1.0,
        autoPlay: true,
        height: Get.size.height / 2,
        scrollPhysics: const BouncingScrollPhysics(),
        autoPlayCurve: Curves.fastLinearToSlowEaseIn,
        autoPlayAnimationDuration: const Duration(milliseconds: 2000),
      ),
    );
  }

  GestureDetector _videoPreview(List<dynamic> images, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => VideoPlayerPage(videoPath: widget.product.videoURL!, appBarTitle: widget.product.name));
      },
      child: Stack(
        children: [
          Positioned.fill(child: CustomWidgets.customImageView(image: images[0], cover: true, borderRadius: BorderRadius.zero)),
          Positioned.fill(child: Container(color: ColorConstants.greyColor.withOpacity(.3))),
          Center(
            child: Container(
              padding: context.padding.normal,
              decoration: BoxDecoration(
                color: ColorConstants.whiteColor.withOpacity(.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconlyBold.play,
                color: ColorConstants.primaryColor,
                size: WidgetSizes.size64.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  FutureBuilder<ProductModel> orderPage() {
    return FutureBuilder<ProductModel>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Loading();
        } else if (snapshot.hasError) {
          return ErrorState(onTap: () => DressesService().getDressesByID(widget.product.id));
        }
        return ListView(
          children: [
            _carouselImages(snapshot.data!.images!),
            textPart(
              name: snapshot.data!.name,
              price: CustomFunctions.findPrice(snapshot.data!.price.toString()),
              machineName: '',
              barcode: snapshot.data!.barcode!,
              category: widget.product.categoryName,
              downloads: snapshot.data!.createdAt,
              views: '${snapshot.data!.views!}',
              desc: snapshot.data!.description!,
              context: context,
            ),
          ],
        );
      },
    );
  }

  FutureBuilder<CollarByIDModel> downloadablePage() {
    return FutureBuilder<CollarByIDModel>(
      future: collar,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Loading();
        } else if (snapshot.hasError) {
          return ErrorState(onTap: () => CollarService().getCollarsByID(widget.product.id));
        }
        return ListView(
          children: [
            _carouselImages(snapshot.data!.images!),
            textPart(
              name: snapshot.data!.name!,
              price: CustomFunctions.findPrice(snapshot.data!.price.toString()),
              barcode: '',
              context: context,
              category: snapshot.data!.tag!,
              desc: snapshot.data!.desc!,
              downloads: snapshot.data!.downloads!.toString(),
              machineName: snapshot.data!.machineName!,
              views: snapshot.data!.views!.toString(),
            ),
          ],
        );
      },
    );
  }

  Widget textPart(
      {required String name,
      required String price,
      required String machineName,
      required String barcode,
      required String category,
      required String views,
      required String downloads,
      required String desc,
      required BuildContext context}) {
    return Padding(
      padding: context.padding.normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 3,
                  style: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    price,
                    style: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.redColor, fontSize: 24),
                  ),
                  Text(
                    ' TMT',
                    style: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.redColor, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: context.padding.verticalNormal,
            child: Text(
              'data'.tr,
              style: context.general.textTheme.titleLarge!.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          twoText(name1: 'data1', name2: machineName, context: context),
          twoText(name1: 'data2', name2: category, context: context),
          // twoText(name1: 'data3', name2: views, context: context),
          twoText(name1: 'data6', name2: barcode, context: context),
          // twoText(name1: 'createdAt', name2: downloads, context: context),
          Padding(
            padding: context.padding.verticalNormal,
            child: Text(
              'data5'.tr,
              style: context.general.textTheme.titleLarge!.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            desc,
            style: context.general.textTheme.titleLarge!.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget twoText({required BuildContext context, required String name1, required String name2}) {
    return name2 == 'null' || name2.isEmpty
        ? SizedBox.shrink()
        : Padding(
            padding: context.padding.onlyTopNormal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        name1.tr,
                        textAlign: TextAlign.left,
                        style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.greyColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        name2.tr,
                        maxLines: 2,
                        textAlign: TextAlign.right,
                        style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.blackColor, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: context.padding.verticalLow,
                  child: Divider(
                    thickness: 1,
                    color: ColorConstants.greyColor.withOpacity(.4),
                  ),
                ),
              ],
            ),
          );
  }
}
