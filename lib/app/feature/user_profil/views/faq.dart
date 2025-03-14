import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/user_profil/models/about_us_model.dart';
import 'package:yaka2/app/feature/user_profil/services/about_us_service.dart';
import 'package:yaka2/app/product/constants/color_constants.dart';
import 'package:yaka2/app/product/custom_widgets/custom_app_bar.dart';
import 'package:yaka2/app/product/empty_state/empty_state.dart';
import 'package:yaka2/app/product/error_state/error_state.dart';

import '../../../product/loadings/loading.dart';

class FAQ extends GetView {
  const FAQ({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'questions', showBackButton: true),
      body: FutureBuilder<List<FAQModel>>(
        future: AboutUsService().getFAQ(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          } else if (snapshot.hasError) {
            return ErrorState(
              onTap: () {
                AboutUsService().getFAQ();
              },
            );
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return EmptyState(name: 'emptyData', type: EmptyStateType.text);
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return ExpansionTile(
                title: Text(
                  snapshot.data![index].title!,
                  style: const TextStyle(
                    color: ColorConstants.blackColor,
                    //fontFamily: normsProMedium,
                    fontSize: 18,
                  ),
                ),
                collapsedIconColor: ColorConstants.blackColor,
                iconColor: ColorConstants.blackColor,
                childrenPadding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 12),
                children: [
                  Text(
                    snapshot.data![index].body!,
                    style: const TextStyle(color: ColorConstants.blackColor, fontSize: 16, height: 1.5),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
