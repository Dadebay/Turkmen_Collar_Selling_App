import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/user_profil/models/about_us_model.dart';
import 'package:yaka2/app/feature/user_profil/services/about_us_service.dart';
import 'package:yaka2/app/product/constants/color_constants.dart';
import 'package:yaka2/app/product/custom_widgets/custom_app_bar.dart';
import 'package:yaka2/app/product/empty_state/empty_state.dart';
import 'package:yaka2/app/product/error_state/error_state.dart';
import 'package:yaka2/app/product/loadings/loading.dart';

class AboutUsView extends GetView {
  const AboutUsView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.whiteColor,
      appBar: CustomAppBar(title: 'aboutUs', showBackButton: true),
      body: FutureBuilder<AboutUsModel>(
        future: AboutUsService().getAboutUs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          } else if (snapshot.hasError) {
            return ErrorState(
              onTap: () {
                AboutUsService().getAboutUs();
              },
            );
          } else if (snapshot.data == null) {
            return EmptyState(name: 'emptyData', type: EmptyStateType.text);
          }
          return Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'contactInformation'.tr,
                    style: const TextStyle(color: ColorConstants.blackColor, fontSize: 20),
                  ),
                ),
                Text(
                  snapshot.data!.body!,
                  textAlign: TextAlign.start,
                  style: const TextStyle(fontSize: 18, color: ColorConstants.blackColor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
