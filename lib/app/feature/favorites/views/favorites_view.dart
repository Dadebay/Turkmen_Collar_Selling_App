import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kartal/kartal.dart';
import 'package:yaka2/app/product/cards/product_card.dart';
import 'package:yaka2/app/product/constants/color_constants.dart';
import 'package:yaka2/app/product/empty_state/empty_state.dart';
import 'package:yaka2/app/product/error_state/error_state.dart';
import 'package:yaka2/app/product/loadings/loading.dart';

import '../controllers/favorites_controller.dart';

class FavoritesView extends StatefulWidget {
  FavoritesView({Key? key}) : super(key: key);

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  final FavoritesController controller = Get.find<FavoritesController>();
  @override
  void initState() {
    super.initState();
    controller.fetchFavoriteCollars();
    controller.fetchFavoriteProducts();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _appBar(context),
        body: TabBarView(
          children: [
            _buildCollarPage(),
            _buildProductPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollarPage() {
    return Obx(() {
      if (controller.isLoadingCollars.value) {
        return Loading();
      } else if (controller.collarError.value.isNotEmpty) {
        return ErrorState(
          onTap: () => controller.fetchFavoriteCollars(),
        );
      } else if (controller.favoriteCollars.isEmpty) {
        return EmptyState(
          name: 'emptyFavoriteSubtitle'.tr,
          type: EmptyStateType.lottie,
        );
      } else {
        return GridView.builder(
          key: const PageStorageKey('collarFavoritesGrid'),
          physics: const BouncingScrollPhysics(),
          itemCount: controller.favoriteCollars.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 9 / 14,
          ),
          itemBuilder: (BuildContext context, int index) {
            final product = controller.favoriteCollars[index];
            print('Collar favorites: ${controller.favoriteCollars[index].id}');
            print('Collar favorites: ${controller.favoriteCollars[index].name}');
            print(product.downloadable);
            return ProductCard(product: product);
          },
        );
      }
    });
  }

  Widget _buildProductPage() {
    return Obx(() {
      if (controller.isLoadingProducts.value) {
        return Loading();
      } else if (controller.productError.value.isNotEmpty) {
        return ErrorState(
          onTap: () => controller.fetchFavoriteProducts(),
        );
      } else if (controller.favoriteProducts.isEmpty) {
        return EmptyState(
          name: 'emptyFavoriteSubtitle'.tr,
          type: EmptyStateType.lottie,
        );
      } else {
        return GridView.builder(
          key: const PageStorageKey('productFavoritesGrid'),
          physics: const BouncingScrollPhysics(),
          itemCount: controller.favoriteProducts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 9 / 14,
          ),
          itemBuilder: (BuildContext context, int index) {
            final product = controller.favoriteProducts[index];

            return ProductCard(product: product);
          },
        );
      }
    });
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'favorites'.tr,
        style: context.general.textTheme.headlineMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      backgroundColor: ColorConstants.primaryColor,
      centerTitle: true,
      bottom: TabBar(
        labelStyle: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: context.general.textTheme.titleLarge,
        labelColor: ColorConstants.whiteColor,
        unselectedLabelColor: ColorConstants.whiteColor.withOpacity(0.7),
        labelPadding: const EdgeInsets.symmetric(vertical: 12),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: ColorConstants.whiteColor,
        indicatorWeight: 3,
        tabs: [
          Tab(text: 'collar'.tr),
          Tab(text: 'products'.tr),
        ],
      ),
    );
  }
}
