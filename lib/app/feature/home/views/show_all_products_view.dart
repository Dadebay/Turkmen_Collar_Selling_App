import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/show_all_products_controller.dart';
import 'package:yaka2/app/feature/home/models/category_model.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/search/view/search_view.dart';
import 'package:yaka2/app/feature/user_profil/models/about_us_model.dart';
import 'package:yaka2/app/feature/user_profil/services/about_us_service.dart';
import 'package:yaka2/app/product/constants/index.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../product/cards/product_card.dart';

class ShowAllProductsView extends StatefulWidget {
  final CategoryModel categoryModel;
  final int? subCatId;
  final int? subCatIndex;
  ShowAllProductsView({required this.categoryModel, this.subCatId, this.subCatIndex, Key? key}) : super(key: key);

  @override
  State<ShowAllProductsView> createState() => _ShowAllProductsViewState();
}

class _ShowAllProductsViewState extends State<ShowAllProductsView> {
  final ShowAllProductsController controller = Get.put(ShowAllProductsController());

  @override
  void initState() {
    super.initState();
    // Eğer bir alt kategori ID'si ve indeksi geldiyse, filtreleme fonksiyonunu çağır
    if (widget.subCatId != null && widget.subCatIndex != null) {
      controller.selectedSubCategory.value = widget.subCatIndex!;
      controller.sortMachineID.value = widget.subCatId!;
      // Ürünleri alt kategoriye göre filtrelemek için onSortonFilterData'yı çağır
      controller.onSortonFilterData(widget.categoryModel.id);
    } else {
      // Sadece ana kategori ürünlerini yükle
      controller.fetchData(widget.categoryModel.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.categoryModel.name,
        showBackButton: true,
        actionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => controller.showSortDialog(widget.categoryModel.id),
              icon: const Icon(Icons.filter_list, color: ColorConstants.whiteColor),
            ),
            if (widget.categoryModel.name == 'Ýakalar')
              IconButton(
                onPressed: () => Get.to(() => SearchView()),
                icon: const Icon(Icons.search, color: ColorConstants.whiteColor),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Yalnızca 'Ýakalar' kategorisi için alt kategorileri göster
          if (widget.categoryModel.name == 'Ýakalar') _subcategories(),
          _page(), // Ürünlerin listelendiği bölüm
        ],
      ),
    );
  }

  // Alt kategorileri listeleyen FutureBuilder
  Widget _subcategories() {
    return FutureBuilder<List<GetFilterElements>>(
      future: AboutUsService().getFilterElements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return Container(
            height: 70,
            child: ListView.builder(
              physics: ClampingScrollPhysics(),
              itemCount: snapshot.data!.length,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    controller.selectedSubCategory.value = index;
                    controller.sortMachineID.value = snapshot.data![index].id!;
                    controller.onSortonFilterData(widget.categoryModel.id);
                  },
                  child: Obx(
                    () => Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.selectedSubCategory.value == index ? ColorConstants.primaryColor : ColorConstants.whiteColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ColorConstants.primaryColor.withOpacity(0.4), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.greyColor.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        snapshot.data![index].name!,
                        style: TextStyle(
                          color: controller.selectedSubCategory.value == index ? ColorConstants.whiteColor : ColorConstants.blackColor,
                          fontSize: 16,
                          fontWeight: controller.selectedSubCategory.value == index ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  // Ürünleri SmartRefresher ile listeleyen sayfa bölümü
  Expanded _page() {
    return Expanded(
      child: Obx(
        () => SmartRefresher(
          footer: ClassicFooter(),
          controller: controller.refreshController,
          onRefresh: () => controller.onRefresh(widget.categoryModel.id),
          onLoading: () => controller.onLoading(widget.categoryModel.id),
          enablePullDown: true,
          enablePullUp: true,
          header: const MaterialClassicHeader(color: ColorConstants.primaryColor),
          child: controller.loading.value
              ? controller.showAllList.isEmpty
                  ? EmptyState(name: 'emptyData', type: EmptyStateType.lottie) // Boş veri durumu
                  : _buildGridView(controller.showAllList) // GridView ile ürünleri göster
              : Center(child: CircularProgressIndicator()), // Yüklenme animasyonu
        ),
      ),
    );
  }

  // Ürünleri 2 sütunlu bir GridView'de gösteren fonksiyon
  Widget _buildGridView(List<ProductModel> list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 9 / 16, // Kartların en-boy oranı
      ),
      itemBuilder: (context, index) {
        final product = ProductModel(
          categoryName: widget.categoryModel.name,
          image: list[index].image,
          name: list[index].name,
          price: list[index].price,
          id: list[index].id,
          downloadable: widget.categoryModel.name == 'Ýakalar',
          createdAt: list[index].createdAt,
        );
        return ProductCard(product: product);
      },
    );
  }
}
