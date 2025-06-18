import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/constants/index.dart';

import '../services/collars_service.dart';

class CollarController extends GetxController {
  RxList<ProductModel> collarList = <ProductModel>[].obs;
  RxInt collarLoading = 0.obs;
  RxInt collarPage = 1.obs;

  Future<void> collarOnLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    collarPage.value += 1;
    await getData();
  }

  Future<void> collarOnRefresh() async {
    collarPage.value = 1;
    collarList.clear();
    collarLoading.value = 2;
    await getData();
  }

  Future<void> getData() async {
    final result = await CollarService().getCollars(
      parametrs: {
        'page': '${collarPage.value}',
        'limit': StringConstants.limit,
      },
    );
    if (result.isEmpty && collarList.isEmpty) {
      collarLoading.value = 1;
    } else {
      collarList.addAll(result);
      collarLoading.value = 2;
    }
  }
}
