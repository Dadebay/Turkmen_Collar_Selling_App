import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/cart/models/downloads_model.dart';
import 'package:yaka2/app/feature/cart/services/downloads_service.dart';
import 'package:yaka2/app/feature/product_profil/views/download_yaka.dart';
import 'package:yaka2/app/product/constants/index.dart';

class DownloadedView extends GetView {
  const DownloadedView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'downloaded', showBackButton: true),
      body: FutureBuilder<List<DownloadsModel>>(
        future: DownloadsService().getDownloadedProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          } else if (snapshot.hasError) {
            return ErrorState(
              onTap: () {
                DownloadsService().getDownloadedProducts();
              },
            );
          } else if (snapshot.data!.isEmpty) {
            return EmptyState(name: 'emptyData', type: EmptyStateType.text);
          }
          return GridView.builder(
            itemCount: snapshot.data!.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1 / 1.7),
            itemBuilder: (BuildContext context, int index) {
              return Container(
                margin: context.padding.low,
                decoration: BoxDecoration(
                  borderRadius: context.border.normalBorderRadius,
                  color: ColorConstants.primaryColorCard,
                  boxShadow: [
                    BoxShadow(color: ColorConstants.greyColor.withOpacity(.3), blurRadius: 2, offset: const Offset(0, 1)),
                  ],
                  border: Border.all(color: ColorConstants.primaryColor.withOpacity(.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        fadeInCurve: Curves.ease,
                        imageUrl: snapshot.data![index].images!.first,
                        imageBuilder: (context, imageProvider) => Container(
                          margin: context.padding.low,
                          decoration: BoxDecoration(
                            borderRadius: context.border.normalBorderRadius,
                            image: DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        placeholder: (context, url) => Loading(),
                        errorWidget: (context, url, error) => NoImage(),
                      ),
                    ),
                    namePart(snapshot.data![index], context),
                    downloadButton(snapshot.data![index], context),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Padding namePart(DownloadsModel model, BuildContext context) {
    final double price = double.parse(model.price.toString()) / 100.0;

    return Padding(
      padding: context.padding.horizontalNormal.copyWith(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              model.name!,
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
              style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.blackColor, fontSize: 18),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  price.toStringAsFixed(price > 1000 ? 0 : 2),
                  overflow: TextOverflow.ellipsis,
                  style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.primaryColor, fontSize: 18),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    ' TMT',
                    style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.primaryColor, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector downloadButton(DownloadsModel model, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        model.files!.isEmpty
            ? showSnackBar('errorTitle', 'noFile', ColorConstants.redColor)
            : Get.to(
                () => DownloadYakaPage(
                  image: model.images!.first,
                  pageName: model.name!,
                  id: model.id!,
                ),
              );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        width: Get.size.width,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: ColorConstants.primaryColor,
          borderRadius: context.border.lowBorderRadius,
        ),
        alignment: Alignment.center,
        child: Text(
          'download'.tr,
          style: context.general.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, color: ColorConstants.whiteColor, fontSize: 18),
        ),
      ),
    );
  }
}
