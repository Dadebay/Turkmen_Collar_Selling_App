import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/category_service.dart';
import 'package:yaka2/app/product/utils/dialog_utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../product/constants/index.dart';

class ShowAllProductsController extends GetxController {
  Rx<int> page = 1.obs;
  Rx<String> sortMachineName = ''.obs;
  Rx<int> sortMachineID = 0.obs;
  Rx<int> sortValueRadioButton = 0.obs;
  Rx<int> selectedSubCategory = (-1).obs; // Başlangıçta hiçbir alt kategori seçili değil
  var showAllList = <ProductModel>[].obs; // Gözlemlenebilir liste
  Rx<bool> loading = false.obs;

  final TextEditingController minimumPriceRangeController = TextEditingController();
  final TextEditingController maximumPriceRangeController = TextEditingController();

  final RefreshController refreshController = RefreshController(initialRefresh: false);

  // Belirtilen kategori ID'si ve filtrelere göre ürünleri getiren fonksiyon
  void fetchData(int id) async {
    final List<ProductModel> list = await CategoryService().getCategoryByID(
      id: id,
      parameters: {
        'page': '${page.value}',
        'limit': '10', // StringConstants.limit yerine sabit bir değer kullandım
        'sort_by': sortMachineName.value,
        'min': minimumPriceRangeController.text,
        'max': maximumPriceRangeController.text,
        'tag': '${sortMachineID.value == 0 ? '' : sortMachineID.value}',
      },
    );

    if (list.isNotEmpty) {
      showAllList.addAll(list);
    }
    loading.value = true;
  }

  // Sayfayı yenileme fonksiyonu
  void onRefresh(int id) {
    loading.value = false;
    page.value = 1;
    showAllList.clear();
    minimumPriceRangeController.clear();
    maximumPriceRangeController.clear();
    sortMachineID.value = 0;
    sortMachineName.value = '';
    selectedSubCategory.value = -1; // Seçili alt kategoriyi sıfırla
    fetchData(id);
    refreshController.refreshCompleted();
  }

  // Daha fazla ürün yükleme fonksiyonu
  void onLoading(int id) {
    page.value++;
    fetchData(id);
    refreshController.loadComplete();
  }

  // Filtreleme veya sıralama yapıldığında verileri yeniden getiren fonksiyon
  void onSortonFilterData(int id) {
    page.value = 1;
    showAllList.clear();
    loading.value = false; // Yükleme durumunu başlat
    fetchData(id);
  }

  // Sıralama seçeneklerini gösteren diyalog
  dynamic showSortDialog(int id) {
    return DialogUtils.defaultBottomSheet(
      name: 'sort',
      context: Get.context!,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: ListConstants.sortData.length,
        itemBuilder: (context, index) {
          return Obx(
            () => RadioListTile(
              value: index,
              groupValue: sortValueRadioButton.value,
              activeColor: ColorConstants.primaryColor,
              onChanged: (ind) {
                sortValueRadioButton.value = int.parse(ind.toString());
                sortMachineName.value = ListConstants.sortData[index]['sort_column'];
                onSortonFilterData(id);
                Get.back();
              },
              title: Text("${ListConstants.sortData[index]['name']}".tr),
            ),
          );
        },
      ),
    );
  }
}