import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kartal/kartal.dart';
import 'package:yaka2/app/feature/favorites/services/fav_service.dart';
import 'package:yaka2/app/feature/home/models/collar_model.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/cards/product_card.dart';
import 'package:yaka2/app/product/constants/color_constants.dart';
import 'package:yaka2/app/product/empty_state/empty_state.dart';
import 'package:yaka2/app/product/error_state/error_state.dart';
import 'package:yaka2/app/product/loadings/loading.dart';

import '../../home/models/clothes_model.dart';
import '../controllers/favorites_controller.dart';

class FavoritesView extends GetView<FavoritesController> {
  @override
  final FavoritesController controller = Get.put(FavoritesController());

  FavoritesView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: appBar(context),
        body: TabBarView(
          children: [
            firstpage(),
            secondPage(),
          ],
        ),
      ),
    );
  }

  FutureBuilder<List<DressesModelFavorites>> secondPage() {
    return FutureBuilder<List<DressesModelFavorites>>(
      future: FavService().getProductFavList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Loading();
        } else if (snapshot.hasError) {
          return ErrorState(
            onTap: () {
              FavService().getProductFavList();
            },
          );
        } else if (snapshot.data!.isEmpty) {
          return EmptyState(name: 'emptyFavoriteSubtitle', type: EmptyStateType.lottie);
        }
        return GridView.builder(
          itemCount: snapshot.data!.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 9 / 14),
          itemBuilder: (BuildContext context, int index) {
            return ProductCard(product: ProductModel.fromJson(snapshot.data![index] as Map));
          },
        );
      },
    );
  }

  FutureBuilder<List<FavoritesModelCollar>> firstpage() {
    return FutureBuilder<List<FavoritesModelCollar>>(
      future: FavService().getCollarFavList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Loading();
        } else if (snapshot.hasError) {
          return ErrorState(
            onTap: () {
              FavService().getProductFavList();
            },
          );
        } else if (snapshot.data!.isEmpty) {
          return EmptyState(name: 'emptyFavoriteSubtitle', type: EmptyStateType.lottie);
        }
        return GridView.builder(
          itemCount: snapshot.data!.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 9 / 14),
          itemBuilder: (BuildContext context, int index) {
            final double a = double.parse(snapshot.data![index].price.toString());
            final double b = a / 100.0;
            final product = ProductModel(id: snapshot.data![index].id!, name: snapshot.data![index].name!, createdAt: snapshot.data![index].createdAt!, image: snapshot.data![index].image!, price: b.toString(), categoryName: '', downloadable: true);
            return ProductCard(product: product);
            // return ProductCard(
            //   categoryName: '',
            //   image: snapshot.data![index].image!,
            //   name: '${snapshot.data![index].name}',
            //   price: b.toString(),
            //   id: snapshot.data![index].id!,
            //   downloadable: true,
            //   createdAt: snapshot.data![index].createdAt!,
            // );
          },
        );
      },
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      title: Text(
        'favorites'.tr,
        style: context.general.textTheme.headlineMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      backgroundColor: ColorConstants.primaryColor,
      systemOverlayStyle: const SystemUiOverlayStyle(statusBarColor: ColorConstants.primaryColor, statusBarIconBrightness: Brightness.dark),
      centerTitle: true,
      bottom: TabBar(
        labelStyle: context.general.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: context.general.textTheme.titleLarge,
        labelColor: ColorConstants.whiteColor,
        unselectedLabelColor: ColorConstants.blackColor,
        labelPadding: const EdgeInsets.only(top: 8, bottom: 4),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: ColorConstants.whiteColor,
        indicatorWeight: 3,
        tabs: [
          Tab(
            text: 'collar'.tr,
          ),
          Tab(
            text: 'products'.tr,
          ),
        ],
      ),
    );
  }
}
