import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

import 'package:lottie/lottie.dart';

import '../constants/icon_constants.dart';
import '../constants/widget_sizes.dart';
import '../l10n/app_translations.dart';
import '../theme/context_extensions.dart';

enum EmptyStateType { text, image, lottie }

class EmptyState extends StatelessWidget {
  const EmptyState({required this.name, required this.type, super.key});
  final String name;
  final EmptyStateType type;

  @override
  Widget build(BuildContext context) {
    return type == EmptyStateType.lottie ? _lottie(context) : _text(context);
  }

  Center _text(BuildContext context) {
    return Center(
      child: Padding(
        padding: context.padding.normal,
        child: Text(
          name.tr,
          textAlign: TextAlign.center,
          style: context.general.textTheme.bodyLarge!.copyWith(
            color: AppPalette.of(context).text,
          ),
        ),
      ),
    );
  }

  Column _lottie(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          IconConstants.noData,
          width: WidgetSizes.size350.value,
          height: WidgetSizes.size350.value,
        ),
        Text(
          name.tr,
          textAlign: TextAlign.center,
          style: context.general.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
