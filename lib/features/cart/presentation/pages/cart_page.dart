import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/buttons/agree_button.dart';
import '../../../../core/widgets/cards/cart_card.dart';
import '../../../../core/widgets/custom_functions.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../../../core/widgets/empty_cart.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../bloc/cart_bloc.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final items = switch (state) {
          CartIdle(:final items) => items,
          CartOrdering(:final items) => items,
          CartOrderError(:final items) => items,
          _ => const <CartItemEntity>[],
        };
        return Column(
          children: [
            if (items.isEmpty)
              const EmptyCart()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return CardCart(productModel: items[index]);
                  },
                ),
              ),
            if (items.isNotEmpty) _OrderDetail(items: items),
          ],
        );
      },
    );
  }
}

class _OrderDetail extends StatelessWidget {
  const _OrderDetail({required this.items});
  final List<CartItemEntity> items;

  @override
  Widget build(BuildContext context) {
    double sum = 0;
    for (final element in items) {
      sum += (double.tryParse(element.price) ?? 0) * element.quantity;
    }
    return Container(
      color: AppPalette.of(context).surface,
      padding: context.padding.normal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: ColorConstants.primaryColor, thickness: 1),
          Padding(
            padding: context.padding.verticalLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'countProducts'.tr,
                  style: context.general.textTheme.bodyLarge!.copyWith(
                    color: AppPalette.of(context).muted,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${items.length}',
                  style: context.general.textTheme.bodyLarge!.copyWith(
                    color: AppPalette.of(context).text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: context.padding.verticalNormal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'priceProduct'.tr,
                  style: context.general.textTheme.bodyLarge!.copyWith(
                    color: AppPalette.of(context).muted,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${CustomFunctions.findPrice(sum.toString())} TMT',
                  style: context.general.textTheme.bodyLarge!.copyWith(
                    color: AppPalette.of(context).text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          AgreeButton(
            text: 'orderProducts',
            fontSize: 16,
            onTap: () {
              final token = sl<LocalStorage>().token;
              if (token == null || token.isEmpty) {
                showSnackBar(
                  context,
                  'loginError',
                  'loginErrorSubtitle',
                  ColorConstants.redColor,
                );
                context.push(AppRoutes.login);
                return;
              }
              if (items.isEmpty) {
                showSnackBar(
                  context,
                  'emptyCart',
                  'emptyCartSubtitle',
                  ColorConstants.redColor,
                );
                return;
              }
              context.push(AppRoutes.order);
            },
          ),
        ],
      ),
    );
  }
}
