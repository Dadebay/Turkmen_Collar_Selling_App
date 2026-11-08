import 'package:flutter/material.dart';

import '../../../../core/constants/border_radius_constants.dart';
import '../../../../core/constants/widget_sizes.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_widgets.dart';

class BannerDetailPage extends StatelessWidget {
  const BannerDetailPage({
    required this.pageName,
    required this.image,
    required this.description,
    super.key,
  });

  final String pageName;
  final String image;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: pageName, showBackButton: true),
      body: Column(
        children: [
          SizedBox(
            height: WidgetSizes.size256.value,
            child: CustomWidgets.customImageView(
              image: image,
              cover: true,
              borderRadius: CustomBorderRadius.lowBorderRadius,
            ),
          ),
          Padding(
            padding: context.padding.normal,
            child: Text(
              description,
              style: context.general.textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
