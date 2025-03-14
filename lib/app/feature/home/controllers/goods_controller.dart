import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/dresses_service.dart';
import 'package:yaka2/app/product/constants/index.dart';

class GoodsController extends GetxController {
  RxList<ProductModel> goodsList = <ProductModel>[].obs;
  RxInt goodsLoading = 0.obs;
  RxInt goodsPage = 1.obs;
  final RefreshController refreshController = RefreshController();

  dynamic goodsOnLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    refreshController.loadComplete();
    goodsPage.value += 1;
    getData();
    refreshController.refreshCompleted();
  }

  dynamic goodsOnRefresh() async {
    goodsPage.value = 1;
    goodsList.clear();
    getData();
    goodsLoading.value = 3;
  }

  dynamic getData() async {
    await DressesService().getGoods(
      parametrs: {'page': '${goodsPage.value}', 'limit': StringConstants.limit},
    ).then((value) {
      if (value.isEmpty) {
        goodsLoading.value = 1;
      } else {
        goodsList.addAll(value);
      }
    });
  }
}
