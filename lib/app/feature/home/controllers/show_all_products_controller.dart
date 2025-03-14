import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/home/services/category_service.dart';
import 'package:yaka2/app/feature/user_profil/services/about_us_service.dart';
import 'package:yaka2/app/product/utils/dialog_utils.dart';

import '../../../product/constants/index.dart';

class ShowAllProductsController extends GetxController {
  Rx<int> page = 1.obs;

  Rx<String> sortMachineName = ''.obs;
  Rx<int> sortMachineID = 0.obs;
  List<ProductModel> showAllList = <ProductModel>[].obs;
  Rx<bool> loading = false.obs;
  final TextEditingController minimumPriceRangeController = TextEditingController();
  final TextEditingController maximumPriceRangeController = TextEditingController();

  final RefreshController refreshController = RefreshController(initialRefresh: false);

  void fetchData(int id) async {
    final List<ProductModel> list = await CategoryService().getCategoryByID(
      id: id,
      parametrs: {
        'page': '${page.value}',
        'limit': StringConstants.limit,
        'sort_by': sortMachineName.value,
        'min': minimumPriceRangeController.text,
        'max': maximumPriceRangeController.text,
        'tag': '${sortMachineID.value == 0 ? '' : sortMachineID.value}',
      },
    );
    
    print(showAllList.length);
    showAllList.addAll(list);
    print(showAllList.length);

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
              groupValue: sortMachineID.value,
              activeColor: ColorConstants.primaryColor,
              onChanged: (ind) {
                sortMachineID.value = ind as int;
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

  dynamic showFilterDialog(int id) {
    DialogUtils.defaultBottomSheet(
      name: 'filter',
      context: Get.context!,
      child: StatefulBuilder(
        builder: (context, setStatee) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('selectMachine'.tr),
                subtitle: Text(sortMachineName.value),
                leading: Icon(Icons.filter_list),
                onTap: () async {
                  final filters = await AboutUsService().getFilterElements();
                  await Get.defaultDialog(
                    title: 'selectMachine'.tr,
                    content: Column(
                      children: filters
                          .map(
                            (filter) => ListTile(
                              title: Text(filter.name!),
                              onTap: () {
                                sortMachineName.value = filter.name!;
                                sortMachineID.value = filter.id!;
                                Get.back();
                              },
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
              TextField(controller: minimumPriceRangeController, decoration: InputDecoration(labelText: 'Min Price')),
              TextField(controller: maximumPriceRangeController, decoration: InputDecoration(labelText: 'Max Price')),
              ElevatedButton(
                onPressed: () {
                  onRefresh(id);
                },
                child: Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
