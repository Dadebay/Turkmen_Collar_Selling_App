// ignore_for_file: always_put_required_named_parameters_first

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/cart/models/history_order_model.dart';
import 'package:yaka2/app/feature/cart/services/history_order_service.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/cards/product_card.dart';
import 'package:yaka2/app/product/constants/color_constants.dart';
import 'package:yaka2/app/product/custom_widgets/custom_app_bar.dart';
import 'package:yaka2/app/product/empty_state/empty_state.dart';
import 'package:yaka2/app/product/loadings/loading.dart';

import '../../../product/error_state/error_state.dart';

class HistoryOrders extends StatelessWidget {
  const HistoryOrders({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'orders', showBackButton: true),
      body: FutureBuilder<List<HistoryOrderModel>>(
        future: HistoryOrderService().getHistoryOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          } else if (snapshot.hasError) {
            return ErrorState(
              onTap: () {
                HistoryOrderService().getHistoryOrders();
              },
            );
          } else if (snapshot.data!.isEmpty) {
            return EmptyState(name: 'emptyData', type: EmptyStateType.text);
          }
          return ListView.separated(
            itemCount: snapshot.data!.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                onTap: () {
                  Get.to(
                    () => HistoryOrderProductID(
                      id: snapshot.data![index].id!,
                      index: index,
                    ),
                  );
                },
                minVerticalPadding: 0.0,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'order'.tr} ${snapshot.data!.length - index}',
                      style: const TextStyle(
                        color: ColorConstants.blackColor,
                        fontSize: 18,
                        //fontFamily: normsProMedium,
                      ),
                    ),
                    Text(
                      snapshot.data![index].status == 'in_review' ? 'waiting'.tr : 'come'.tr,
                      style: const TextStyle(
                        color: ColorConstants.greyColor,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${snapshot.data![index].totalCost! / 100}',
                          style: const TextStyle(
                            color: ColorConstants.primaryColor,
                            fontSize: 18,
                            //fontFamily: normProBold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            ' TMT',
                            style: TextStyle(
                              color: ColorConstants.redColor,
                              fontSize: 12,
                              //fontFamily: normsProMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Divider(
                  color: ColorConstants.greyColor,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class HistoryOrderProductID extends StatelessWidget {
  final int index;
  final int id;

  const HistoryOrderProductID({Key? key, required this.index, required this.id}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'order'.tr + ' ${index + 1}'.tr,
        showBackButton: true,
      ),
      body: FutureBuilder<List<ProductsModelMini>>(
        future: HistoryOrderService().getHistoryOrderByID(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          } else if (snapshot.hasError) {
            return ErrorState(
              onTap: () {
                HistoryOrderService().getHistoryOrderByID(id);
              },
            );
          } else if (snapshot.data!.isEmpty) {
            return EmptyState(name: 'emptyData', type: EmptyStateType.text);
          }
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemBuilder: (BuildContext context, int index) {
              final product = ProductModel(
                categoryName: '',
                image: snapshot.data![index].image!,
                name: '${snapshot.data![index].name}',
                price: '${snapshot.data![index].price}',
                id: snapshot.data![index].id!,
                downloadable: false,
                createdAt: '',
              );
              return ProductCard(product: product);
              // return ProductCard(
              //   categoryName: '',
              //   image: snapshot.data![index].image!,
              //   name: '${snapshot.data![index].name}',
              //   price: '${snapshot.data![index].price}',
              //   id: snapshot.data![index].id!,
              //   downloadable: false,
              //   createdAt: '',
              // );
            },
          );
        },
      ),
    );
  }
}
