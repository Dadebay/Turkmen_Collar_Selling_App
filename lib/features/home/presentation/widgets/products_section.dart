import 'package:flutter/material.dart';

import '../../../../core/constants/widget_sizes.dart';
import '../../../../core/widgets/cards/machine_card.dart';
import '../../../../core/widgets/cards/product_card.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../../domain/entities/product_entity.dart';

class ProductsSection extends StatelessWidget {
  const ProductsSection({
    required this.titleKey,
    required this.products,
    this.isMachine = false,
    super.key,
  });

  final String titleKey;
  final List<ProductEntity> products;
  final bool isMachine;

  @override
  Widget build(BuildContext context) {
    if (isMachine) {
      return SizedBox(
        height: WidgetSizes.size256.value,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomWidgets.listViewBuilderName(
              text: titleKey,
              context: context,
              showIcon: false,
              onTap: () {},
            ),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemBuilder: (context, index) =>
                    MachineCard(productModel: products[index]),
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: WidgetSizes.size350.value,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomWidgets.listViewBuilderName(
            text: titleKey,
            context: context,
            showIcon: false,
            onTap: () {},
          ),
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              addAutomaticKeepAlives: true,
              itemBuilder: (context, index) =>
                  ProductCard(product: products[index]),
            ),
          ),
        ],
      ),
    );
  }
}
