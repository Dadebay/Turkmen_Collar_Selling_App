import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/search/controller/search_view_controller.dart';
import 'package:yaka2/app/product/cards/product_card.dart';
import 'package:yaka2/app/product/constants/index.dart';

class SearchView extends StatefulWidget {
  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  TextEditingController controller = TextEditingController();

  final SearchViewController searchController = Get.put(SearchViewController());

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'search', showBackButton: true),
      body: Column(
        children: [
          Padding(
            padding: context.padding.normal.copyWith(top: 0, bottom: 0),
            child: CustomTextField(
              labelName: 'search',
              onChanged: (String value) {
                searchController.onSearchTextChanged(value.toString());
              },
              prefixIcon: Icon(
                IconlyLight.search,
                size: 28,
                color: ColorConstants.greyColor,
              ),
              controller: controller,
              focusNode: FocusNode(),
              requestfocusNode: FocusNode(),
              isNumber: false,
            ),
          ),
          Obx(
            () {
              return searchController.loadingData.value
                  ? Loading()
                  : searchController.productsList.isEmpty
                      ? EmptyState(name: 'emptyData', type: EmptyStateType.lottie)
                      : Expanded(
                          child: GridView.builder(
                            physics: BouncingScrollPhysics(),
                            itemCount: searchController.productsList.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 9 / 16),
                            itemBuilder: (context, index) {
                              return ProductCard(product: searchController.productsList[index]);
                            },
                          ),
                        );
            },
          ),
        ],
      ),
    );
  }
}
