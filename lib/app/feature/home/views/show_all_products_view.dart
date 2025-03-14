import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/home/controllers/show_all_products_controller.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/constants/index.dart';

import '../../../product/cards/product_card.dart';

class ShowAllProductsView extends StatefulWidget {
  final int id;
  final String name;
  ShowAllProductsView({required this.name, required this.id, Key? key}) : super(key: key);

  @override
  State<ShowAllProductsView> createState() => _ShowAllProductsViewState();
}

class _ShowAllProductsViewState extends State<ShowAllProductsView> {
  final ShowAllProductsController controller = Get.put(ShowAllProductsController());

  @override
  void initState() {
    super.initState();
    controller.fetchData(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.name,
        showBackButton: true,
        actionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                controller.showSortDialog(widget.id);
              },
              icon: const Icon(IconlyLight.filter, color: ColorConstants.whiteColor),
            ),
            GestureDetector(
              onTap: () {
                controller.showFilterDialog(widget.id);
              },
              child: const Icon(IconlyLight.filter2, color: ColorConstants.whiteColor),
            ),
          ],
        ),
      ),
      body: Obx(
        () => SmartRefresher(
          controller: controller.refreshController,
          onRefresh: () {
            controller.onRefresh(widget.id);
          },
          onLoading: () {
            controller.onLoading(widget.id);
          },
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
          categoryName: widget.name.tr,
          image: list[index].image,
          name: list[index].name,
          price: (double.parse(list[index].price.toString()) / 100.0).toString(),
          id: list[index].id,
          downloadable: widget.name == 'Ýakalar',
          createdAt: list[index].createdAt,
        );
        return ProductCard(product: product);
      },
    );
  }
}
