import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/constants/index.dart';

import '../services/collars_service.dart';

class CollarController extends GetxController {
  RxList<ProductModel> collarList = <ProductModel>[].obs;
  RxInt collarLoading = 0.obs;
  RxInt collarPage = 1.obs;
  final RefreshController refreshController = RefreshController();

  dynamic collarOnLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    refreshController.loadComplete();

    collarPage.value += 1;
    getData();
    refreshController.refreshCompleted();
  }

  dynamic collarOnRefresh() async {
    collarPage.value = 1;
    collarList.clear();
    getData();
    collarLoading.value = 2;
  }

  dynamic getData() async {
    await CollarService().getCollars(
      parametrs: {'page': '${collarPage.value}', 'limit': StringConstants.limit},
    ).then((value) {
      if (value.isEmpty) {
        collarLoading.value = 1;
      } else {
        collarList.addAll(value);
      }
    });
  }
}
