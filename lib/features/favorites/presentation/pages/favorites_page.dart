import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/cards/product_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../bloc/favorites_bloc.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    context.read<FavoritesBloc>().add(const FavoritesLoadRequested());
  }

  void _refresh() {
    context.read<FavoritesBloc>().add(const FavoritesLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _appBar(context),
        body: BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, state) {
            return TabBarView(
              children: [
                _buildGrid(
                  state: state,
                  picker: (loaded) => loaded.collars,
                  pageStorageKey: 'collarFavoritesGrid',
                ),
                _buildGrid(
                  state: state,
                  picker: (loaded) => loaded.products,
                  pageStorageKey: 'productFavoritesGrid',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid({
    required FavoritesState state,
    required List<ProductEntity> Function(FavoritesLoaded) picker,
    required String pageStorageKey,
  }) {
    if (state is FavoritesLoading) {
      return const Loading();
    }
    if (state is FavoritesError) {
      return ErrorState(onTap: _refresh);
    }
    // FavoritesInitial (not loaded yet — e.g. a signed-out user) is treated as
    // an empty list; the list is loaded globally once the user is authenticated
    // and can be re-fetched via refresh.
    if (state is FavoritesInitial) {
      return const EmptyState(
        name: 'emptyFavoriteSubtitle',
        type: EmptyStateType.lottie,
      );
    }
    if (state is FavoritesLoaded) {
      final items = picker(state);
      if (items.isEmpty) {
        return const EmptyState(
          name: 'emptyFavoriteSubtitle',
          type: EmptyStateType.lottie,
        );
      }
      return GridView.builder(
        key: PageStorageKey<String>(pageStorageKey),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 9 / 14,
        ),
        itemBuilder: (BuildContext context, int index) {
          return ProductCard(product: items[index]);
        },
      );
    }
    return const SizedBox.shrink();
  }

  AppBar _appBar(BuildContext context) {
    final appBarForeground =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      title: Text(
        'favorites'.tr,
        style: context.general.textTheme.headlineMedium!.copyWith(
          color: appBarForeground,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      bottom: TabBar(
        labelStyle: context.general.textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        unselectedLabelStyle: context.general.textTheme.titleLarge?.copyWith(
          fontSize: 14,
        ),
        labelColor: appBarForeground,
        unselectedLabelColor: appBarForeground.withOpacity(0.7),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorColor: isDark ? ColorConstants.primaryColor : appBarForeground,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Text(
              'collar'.tr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Tab(
            child: Text(
              'products'.tr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
