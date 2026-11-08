import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/cards/product_card.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../injection_container.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../data/datasources/history_orders_remote_data_source.dart';
import '../../data/models/history_order_model.dart';

class HistoryOrdersPage extends StatefulWidget {
  const HistoryOrdersPage({super.key});

  @override
  State<HistoryOrdersPage> createState() => _HistoryOrdersPageState();
}

class _HistoryOrdersPageState extends State<HistoryOrdersPage> {
  late Future<Result<List<HistoryOrderModel>>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<HistoryOrdersRemoteDataSource>().getHistoryOrders();
  }

  void _retry() {
    setState(() {
      _future = sl<HistoryOrdersRemoteDataSource>().getHistoryOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'orders', showBackButton: true),
      body: FutureBuilder<Result<List<HistoryOrderModel>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loading();
          }
          final result = snapshot.data;
          if (result == null || result is Failure) {
            return ErrorState(onTap: _retry);
          }
          final orders = result.dataOrThrow;
          if (orders.isEmpty) {
            return const EmptyState(
              name: 'emptyData',
              type: EmptyStateType.text,
            );
          }
          return ListView.separated(
            itemCount: orders.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Divider(color: AppPalette.of(context).muted),
              );
            },
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HistoryOrderProductIdPage(
                        id: order.id ?? 0,
                        index: index,
                      ),
                    ),
                  );
                },
                minVerticalPadding: 0.0,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'order'.tr} ${index + 1}',
                      style: TextStyle(
                        color: AppPalette.of(context).text,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      order.status == 'in_review' ? 'waiting'.tr : 'come'.tr,
                      style: TextStyle(
                        color: AppPalette.of(context).muted,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${(order.totalCost ?? 0) / 100}',
                          style: const TextStyle(
                            color: ColorConstants.primaryColor,
                            fontSize: 18,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            ' TMT',
                            style: TextStyle(
                              color: ColorConstants.redColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class HistoryOrderProductIdPage extends StatefulWidget {
  const HistoryOrderProductIdPage({
    required this.id,
    required this.index,
    super.key,
  });

  final int index;
  final int id;

  @override
  State<HistoryOrderProductIdPage> createState() =>
      _HistoryOrderProductIdPageState();
}

class _HistoryOrderProductIdPageState extends State<HistoryOrderProductIdPage> {
  late Future<Result<List<ProductsModelMini>>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<HistoryOrdersRemoteDataSource>().getHistoryOrderById(
      widget.id,
    );
  }

  void _retry() {
    setState(() {
      _future = sl<HistoryOrdersRemoteDataSource>().getHistoryOrderById(
        widget.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '${'order'.tr} ${widget.index + 1}',
        showBackButton: true,
      ),
      body: FutureBuilder<Result<List<ProductsModelMini>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loading();
          }
          final result = snapshot.data;
          if (result == null || result is Failure) {
            return ErrorState(onTap: _retry);
          }
          final items = result.dataOrThrow;
          if (items.isEmpty) {
            return const EmptyState(
              name: 'emptyData',
              type: EmptyStateType.text,
            );
          }
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2 / 3,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final mini = items[index];
              final product = ProductEntity(
                id: mini.id ?? 0,
                name: mini.name ?? '',
                price: '${mini.price ?? 0}',
                image: mini.image ?? '',
                categoryName: '',
                downloadable: false,
                quantity: mini.quantity ?? 0,
                createdAt: '',
              );
              return ProductCard(product: product, hideCartButton: true);
            },
          );
        },
      ),
    );
  }
}
