import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/show_all_products_controller.dart';
import 'package:yaka2/app/feature/home/models/category_model.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/feature/search/view/search_view.dart';
import 'package:yaka2/app/feature/user_profil/models/about_us_model.dart';
import 'package:yaka2/app/feature/user_profil/services/about_us_service.dart';
import 'package:yaka2/app/product/constants/index.dart';

import '../../../product/cards/product_card.dart';

class ShowAllProductsView extends StatefulWidget {
  final CategoryModel categoryModel;
  ShowAllProductsView({required this.categoryModel, Key? key}) : super(key: key);

  @override
  State<ShowAllProductsView> createState() => _ShowAllProductsViewState();
}

class _ShowAllProductsViewState extends State<ShowAllProductsView> {
  final ShowAllProductsController controller = Get.put(ShowAllProductsController());

  @override
  void initState() {
    super.initState();
    controller.fetchData(widget.categoryModel.id);
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
              icon: const Icon(IconlyLight.filter, color: ColorConstants.whiteColor),
            ),
            widget.categoryModel.name == 'Ýakalar'
                ? IconButton(
                    onPressed: () => Get.to(() => SearchView()),
                    icon: const Icon(IconlyLight.search, color: ColorConstants.whiteColor),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
      body: Column(
        children: [
          widget.categoryModel.name == 'Ýakalar' ? _subcategories() : SizedBox.shrink(),
          _page(),
        ],
      ),
    );
  }

  FutureBuilder<List<GetFilterElements>> _subcategories() {
    return FutureBuilder<List<GetFilterElements>>(
      future: AboutUsService().getFilterElements(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            height: WidgetSizes.size80.value,
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: snapshot.data!.length,
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    controller.selectedSubCategory.value = index;
                    // controller.sortMachineName.value = snapshot.data![index].name!;
                    controller.sortMachineID.value = snapshot.data![index].id!;
                    controller.onSortonFilterData(widget.categoryModel.id);
                  },
                  child: Obx(
                    () => Container(
                      padding: context.padding.horizontalNormal,
                      margin: context.padding.normal.copyWith(right: 6, left: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.selectedSubCategory.value == index ? ColorConstants.primaryColor : ColorConstants.whiteColor,
                        borderRadius: CustomBorderRadius.normalBorderRadius,
                        border: Border.all(color: ColorConstants.primaryColor.withOpacity(.4), width: 1),
                        boxShadow: [
                          BoxShadow(color: ColorConstants.greyColor.withOpacity(.3), spreadRadius: 3, blurRadius: 3),
                        ],
                      ),
                      child: Text(
                        snapshot.data![index].name!,
                        style: context.general.textTheme.bodyLarge!.copyWith(color: ColorConstants.blackColor, fontSize: 18, fontWeight: controller.selectedSubCategory.value == index ? FontWeight.bold : FontWeight.w400),
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

  Expanded _page() {
    return Expanded(
      child: Obx(
        () => SmartRefresher(
          footer: footer(),
          controller: controller.refreshController,
          onRefresh: () => controller.onRefresh(widget.categoryModel.id),
          onLoading: () => controller.onLoading(widget.categoryModel.id),
          enablePullDown: true,
          enablePullUp: true,
          header: const MaterialClassicHeader(color: ColorConstants.primaryColor),
          child: controller.loading.value
              ? controller.showAllList.isEmpty && controller.sortMachineName.isNotEmpty
                  ? EmptyState(name: 'emptyData', type: EmptyStateType.lottie)
                  : _buildGridView(controller.showAllList)
              : Loading(),
        ),
      ),
    );
  }

  Widget _buildGridView(List<ProductModel> list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      itemCount: list.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 9 / 16),
      itemBuilder: (context, index) {
        final product = ProductModel(
          categoryName: widget.categoryModel.name.tr,
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
