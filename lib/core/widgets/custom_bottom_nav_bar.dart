import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../l10n/app_translations.dart';
import '../theme/color_constants.dart';
import '../icons/app_icon.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<Object> unselectedIcons;
  final List<Object> selectedIcons;
  final List<String> labels;
  final Function(int) onTap;

  const CustomBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.unselectedIcons,
    required this.selectedIcons,
    required this.labels,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 64 + bottomPadding,
      padding: EdgeInsets.only(top: 8, bottom: bottomPadding),
      decoration: BoxDecoration(
        color: AppPalette.of(context).surface,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor.withOpacity(.2),
            spreadRadius: 1,
            blurRadius: 2,
          ),
        ],
      ),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final cartCount = cartState is CartIdle
              ? cartState.items.length
              : (cartState is CartOrdering ? cartState.items.length : 0);
          return Row(
            children: List.generate(selectedIcons.length, (index) {
              final isSelected = index == currentIndex;
              return Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: isSelected ? 0.0 : 1.0,
                    end: isSelected ? 1.0 : 0.0,
                  ),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: SizedBox(
                        height: 48,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index == 2)
                                cartCount == 0
                                    ? _buildIcon(
                                        context,
                                        isSelected,
                                        index,
                                        value,
                                      )
                                    : _buildBadgedIcon(
                                        context,
                                        isSelected,
                                        index,
                                        value,
                                        cartCount,
                                      )
                              else
                                _buildIcon(context, isSelected, index, value),
                              const SizedBox(height: 3),
                              Text(
                                labels[index].tr,
                                style: TextStyle(
                                  color: Color.lerp(
                                    AppPalette.of(context).muted,
                                    ColorConstants.primaryColor,
                                    value,
                                  ),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildIcon(
    BuildContext context,
    bool isSelected,
    int index,
    double value,
  ) {
    return AppIcon(
      isSelected ? selectedIcons[index] : unselectedIcons[index],
      size: 22,
      color: Color.lerp(
        AppPalette.of(context).muted,
        ColorConstants.primaryColor,
        value,
      ),
    );
  }

  Widget _buildBadgedIcon(
    BuildContext context,
    bool isSelected,
    int index,
    double value,
    int count,
  ) {
    return badges.Badge(
      badgeContent: Text(
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: _buildIcon(context, isSelected, index, value),
    );
  }
}
