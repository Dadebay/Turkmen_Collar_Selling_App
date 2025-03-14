import 'package:badges/badges.dart' as badges;
import 'package:get/get.dart';
import 'package:yaka2/app/feature/cart/controllers/cart_controller.dart';

import '../constants/index.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<IconData> unselectedIcons;
  final List<IconData> selectedIcons;
  final Function(int) onTap;

  CustomBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.unselectedIcons,
    required this.selectedIcons,
    Key? key,
  }) : super(key: key);

  final CartController cartController = Get.put<CartController>(CartController());

  @override
  Widget build(BuildContext context) {
    return Container(
      height: WidgetSizes.size64.value,
      decoration: BoxDecoration(
        color: ColorConstants.whiteColor,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor.withOpacity(.2),
            spreadRadius: 1,
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(selectedIcons.length, (index) {
          final isSelected = index == currentIndex;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: isSelected ? 0.0 : 1.0, end: isSelected ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return GestureDetector(
                onTap: () => onTap(index),
                child: GetBuilder<CartController>(
                  builder: (_) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (index == 2) cartController.cartList.isEmpty ? _buildIcon(isSelected, index, value) : _buildBadgedIcon(isSelected, index, value) else _buildIcon(isSelected, index, value),
                        const SizedBox(height: 5),
                        _buildIndicator(isSelected, context),
                      ],
                    );
                  },
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildIcon(bool isSelected, int index, double value) {
    return Icon(
      isSelected ? selectedIcons[index] : unselectedIcons[index],
      size: 28,
      color: Color.lerp(ColorConstants.greyColor, ColorConstants.primaryColor, value),
    );
  }

  Widget _buildBadgedIcon(bool isSelected, int index, double value) {
    return badges.Badge(
      badgeContent: Obx(
        () => Text(
          cartController.cartList.length.toString(),
          style: const TextStyle(color: ColorConstants.whiteColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      child: _buildIcon(isSelected, index, value),
    );
  }

  Widget _buildIndicator(bool isSelected, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isSelected ? 4 : 0,
      width: 16,
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor,
        borderRadius: context.border.normalBorderRadius,
      ),
    );
  }
}
