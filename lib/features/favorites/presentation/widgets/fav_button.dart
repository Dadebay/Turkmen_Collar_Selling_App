import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/border_radius_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/custom_widgets.dart';
import '../bloc/favorites_bloc.dart';
import '../../../../core/icons/app_icon.dart';

class FavButton extends StatelessWidget {
  final int id;
  final bool isCollar;
  final String name;
  final bool? changeBackColor;

  const FavButton({
    required this.isCollar,
    required this.id,
    this.name = '',
    this.changeBackColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        final bool isFavorite =
            state is FavoritesLoaded && state.isFav(id, isCollar: isCollar);

        final bool usePrimaryBackground = changeBackColor == true;
        final Color backgroundColor = usePrimaryBackground
            ? ColorConstants.primaryColor
            : AppPalette.of(context).surface;
        final Color iconColor;
        if (isFavorite) {
          iconColor = ColorConstants.redColor;
        } else {
          iconColor = usePrimaryBackground
              ? Colors.white
              : AppPalette.of(context).text;
        }

        return GestureDetector(
          onTap: () {
            final token = LocalStorage().token;
            if (token == null || token.isEmpty) {
              showSnackBar(
                context,
                'loginError',
                'loginErrorSubtitle1',
                ColorConstants.redColor,
              );
              context.push(AppRoutes.login);
              return;
            }
            context.read<FavoritesBloc>().add(
              FavoritesToggleRequested(id: id, isCollar: isCollar),
            );
          },
          child: Container(
            padding: context.padding.low,
            decoration: BoxDecoration(
              borderRadius: CustomBorderRadius.normalBorderRadius,
              color: backgroundColor,
              boxShadow: [
                if (!usePrimaryBackground)
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: AppIcon(
              isFavorite ? IconlyBold.heart : IconlyLight.heart,
              color: iconColor,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
