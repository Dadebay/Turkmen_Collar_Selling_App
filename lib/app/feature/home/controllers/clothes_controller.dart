import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/dresses_service.dart';
import 'package:yaka2/app/product/constants/index.dart';

class ClothesController extends GetxController {
  RxList<ProductModel> clothesList = <ProductModel>[].obs;
  RxInt clothesLoading = 0.obs;
  RxInt clothesPage = 1.obs;
  final RefreshController refreshController = RefreshController();

  void onLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    refreshController.loadComplete();
    clothesPage.value += 1;
    getData();
    refreshController.refreshCompleted();
  }

  dynamic collarOnRefresh() async {
    clothesPage.value = 1;
    clothesList.clear();
    getData();
  }

  dynamic getData() async {
    await DressesService().getDresses(
      parametrs: {'page': '${clothesPage.value}', 'limit': StringConstants.limit, 'home': '1'},
    ).then((value) {
      if (value.isEmpty) {
        clothesLoading.value = 3;
      } else {
        clothesList.addAll(value);
      }
    });
  }
}
