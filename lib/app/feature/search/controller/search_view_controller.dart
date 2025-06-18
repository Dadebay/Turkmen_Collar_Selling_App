import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/category_service.dart';

class SearchViewController extends GetxController {
  RxList<ProductModel> productsList = <ProductModel>[].obs;
  RxBool loadingData = false.obs;

  dynamic getClientStream(String whereToSearch) async {
    loadingData.value = true;
    if (productsList.isEmpty) {}
    loadingData.value = false;
  }

  dynamic onSearchTextChanged(String word) async {
    loadingData.value = true;
    productsList.clear();
    await CategoryService.searchCollars(query: word).then((value) {
      productsList.addAll(value);
    });

    loadingData.value = false;
  }
}
