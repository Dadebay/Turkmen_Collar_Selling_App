import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../features/cart/domain/entities/cart_item_entity.dart';
import '../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../features/home/domain/entities/product_entity.dart';
import '../../constants/border_radius_constants.dart';
import '../../router/app_router.dart';
import '../../storage/local_storage.dart';
import '../../theme/color_constants.dart';
import '../../theme/context_extensions.dart';
import 'agree_button.dart';
import '../../icons/app_icon.dart';

class AddCartButton extends StatelessWidget {
  final ProductEntity productModel;
  final bool productProfilDesign;
  final bool compact;

  const AddCartButton({
    required this.productModel,
    required this.productProfilDesign,
    this.compact = false,
    super.key,
  });

  CartItemEntity _toCartItem() => CartItemEntity(
    id: productModel.id,
    name: productModel.name,
    price: productModel.price,
    image: productModel.image,
    quantity: 1,
    categoryName: productModel.categoryName,
  );

  int _quantityIn(List<CartItemEntity> items) {
    return items
        .firstWhere(
          (item) => item.id == productModel.id,
          orElse: () => CartItemEntity(
            id: -1,
            name: '',
            price: '0',
            image: '',
            quantity: 0,
            categoryName: '',
          ),
        )
        .quantity;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final items = state is CartIdle
            ? state.items
            : (state is CartOrdering ? state.items : <CartItemEntity>[]);
        final quantity = _quantityIn(items);
        if (quantity > 0) {
          return _buildQuantityChanger(context, quantity);
        }
        return productProfilDesign
            ? _addCartButtonProductProfil(context)
            : _buildAddButton(context);
      },
    );
  }

  void _add(BuildContext context) {
    context.read<CartBloc>().add(CartItemAdded(_toCartItem()));
  }

  void _remove(BuildContext context) {
    context.read<CartBloc>().add(CartItemRemoved(productModel.id));
  }

  Widget _addCartButtonProductProfil(BuildContext context) {
    return Padding(
      padding: context.padding.normal,
      child: AgreeButton(onTap: () => _add(context), text: 'addCart'),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Row(
      mainAxisAlignment: productProfilDesign
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => _add(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor,
              borderRadius: productProfilDesign
                  ? context.border.normalBorderRadius
                  : context.border.lowBorderRadius,
            ),
            child: AppIcon(IconlyBold.bag, color: Colors.white),
          ),
        ),
        // Replaces the old `tel://` call button: contacts support via AI chat,
        // gating on login first (matches the AddMoney support entry point).
        IconButton(
          onPressed: () => _openSupportChat(context),
          icon: const AppIcon(
            IconlyLight.message,
            color: ColorConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  void _openSupportChat(BuildContext context) {
    final isLoggedIn = (LocalStorage().token ?? '').isNotEmpty;
    if (!isLoggedIn) {
      context.push(AppRoutes.login);
      return;
    }
    context.push(AppRoutes.aiChat);
  }

  Widget _buildQuantityChanger(BuildContext context, int quantity) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: context.border.normalBorderRadius,
        color: productProfilDesign
            ? ColorConstants.primaryColorCard
            : Colors.transparent,
      ),
      margin: productProfilDesign ? context.padding.normal : EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIconButton(
            context: context,
            icon: CupertinoIcons.minus,
            onTap: () => _remove(context),
          ),
          Expanded(
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: context.general.textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 16 : (productProfilDesign ? 24 : 20),
              ),
            ),
          ),
          _buildIconButton(
            context: context,
            icon: CupertinoIcons.add,
            onTap: () => _add(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: productProfilDesign
            ? context.padding.normal
            : const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: ColorConstants.primaryColor,
          borderRadius: CustomBorderRadius.lowBorderRadius,
        ),
        child: AppIcon(icon, color: Colors.white),
      ),
    );
  }
}
