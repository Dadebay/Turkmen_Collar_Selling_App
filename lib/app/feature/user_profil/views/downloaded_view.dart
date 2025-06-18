import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yaka2/app/feature/cart/models/downloads_model.dart';
import 'package:yaka2/app/feature/cart/services/downloads_service.dart';
import 'package:yaka2/app/feature/home/models/product_model.dart';
import 'package:yaka2/app/product/cards/product_card.dart';
import 'package:yaka2/app/product/constants/index.dart';

class DownloadedView extends GetView {
  const DownloadedView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'downloaded', showBackButton: true),
      body: FutureBuilder<List<DownloadsModel>>(
        future: DownloadsService().getDownloadedProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          } else if (snapshot.hasError) {
            return ErrorState(
              onTap: () => DownloadsService().getDownloadedProducts(),
            );
          } else if (snapshot.data!.isEmpty) {
            return EmptyState(name: 'emptyData', type: EmptyStateType.text);
          }
          return GridView.builder(
            itemCount: snapshot.data!.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1 / 1.7),
            itemBuilder: (BuildContext context, int index) {
              final product = ProductModel(id: snapshot.data![index].id!, name: snapshot.data![index].name!, createdAt: snapshot.data![index].createdAt!, image: snapshot.data![index].images![0], price: snapshot.data![index].price.toString(), categoryName: 'Ýakalar', downloadable: true);
              return ProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}
