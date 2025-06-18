import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/category_service.dart';
import 'package:yaka2/app/product/utils/dialog_utils.dart';

import '../../../product/constants/index.dart';

class ShowAllProductsController extends GetxController {
  Rx<int> page = 1.obs;

  Rx<String> sortMachineName = ''.obs;
  Rx<int> sortMachineID = 0.obs;
  // Rx<int> sortValue = 0.obs;
  Rx<int> sortValueRadioButton = 0.obs;
  Rx<int> selectedSubCategory = 0.obs;
  List<ProductModel> showAllList = <ProductModel>[].obs;
  Rx<bool> loading = false.obs;
  final TextEditingController minimumPriceRangeController = TextEditingController();
  final TextEditingController maximumPriceRangeController = TextEditingController();

  final RefreshController refreshController = RefreshController(initialRefresh: false);

  void fetchData(int id) async {
    final List<ProductModel> list = await CategoryService().getCategoryByID(
      id: id,
      parameters: {
        'page': '${page.value}',
        'limit': StringConstants.limit,
        'sort_by': sortMachineName.value,
        'min': minimumPriceRangeController.text,
        'max': maximumPriceRangeController.text,
        'tag': '${sortMachineID.value == 0 ? '' : sortMachineID.value}',
      },
    );

    showAllList.addAll(list);

    loading.value = true;
  }

  dynamic onRefresh(int id) {
    loading.value = false;
    page.value = 1;
    showAllList.clear();
    minimumPriceRangeController.clear();
    maximumPriceRangeController.clear();
    sortMachineID.value = 0;
    sortMachineName.value = '';
    selectedSubCategory.value = -1;
    fetchData(id);
    refreshController.refreshCompleted();
  }

  dynamic onLoading(int id) {
    page.value += 1;
    fetchData(id);
    refreshController.loadComplete();
  }

  dynamic onSortonFilterData(int id) {
    page.value = 1;
    showAllList.clear();
    minimumPriceRangeController.clear();
    maximumPriceRangeController.clear();
    fetchData(id);
  }

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
                // sortMachineID.value = 0;
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
