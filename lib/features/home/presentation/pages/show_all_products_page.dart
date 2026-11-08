import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/list_constants.dart';
import '../../../../core/icons/app_icon.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/result/result.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/cards/product_card.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../features/user_profile/data/datasources/profile_meta_remote_data_source.dart';
import '../../../../features/user_profile/data/models/meta_models.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/show_all_products/show_all_products_bloc.dart';

class ShowAllProductsPage extends StatelessWidget {
  const ShowAllProductsPage({
    required this.category,
    this.categoryEntity,
    this.subCatId,
    this.subCatIndex,
    super.key,
  });

  final String category;
  final CategoryEntity? categoryEntity;
  final int? subCatId;
  final int? subCatIndex;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShowAllProductsBloc>(
      create: (_) => sl<ShowAllProductsBloc>()
        ..add(
          ShowAllProductsInitialized(
            categoryId: categoryEntity?.id ?? 0,
            subCategoryId: subCatId,
            subCategoryIndex: subCatIndex,
          ),
        ),
      child: _ShowAllProductsView(
        category: category,
        categoryEntity: categoryEntity,
      ),
    );
  }
}

class _ShowAllProductsView extends StatefulWidget {
  const _ShowAllProductsView({
    required this.category,
    required this.categoryEntity,
  });
  final String category;
  final CategoryEntity? categoryEntity;

  @override
  State<_ShowAllProductsView> createState() => _ShowAllProductsViewState();
}

class _ShowAllProductsViewState extends State<_ShowAllProductsView> {
  static const _prefetchDistance = 900.0;
  static const _sortIcons = <IconData>[
    Icons.sort_rounded,
    Icons.arrow_upward_rounded,
    Icons.arrow_downward_rounded,
    Icons.calendar_today_outlined,
    Icons.history_rounded,
    Icons.visibility_outlined,
  ];

  final ScrollController _scrollController = ScrollController();
  Future<Result<List<FilterElementModel>>>? _subCategoriesFuture;

  String get _name => widget.categoryEntity?.name ?? widget.category;
  bool get _isYakalar =>
      widget.categoryEntity?.isCollar == true || _name == 'Ýakalar';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    if (_isYakalar) {
      _subCategoriesFuture = sl<ProfileMetaRemoteDataSource>()
          .getFilterElements();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter > _prefetchDistance) {
      return;
    }
    final bloc = context.read<ShowAllProductsBloc>();
    final state = bloc.state;
    if (state.status == ShowAllProductsStatus.success &&
        state.items.isNotEmpty &&
        !state.reachedEnd) {
      bloc.add(const ShowAllProductsLoadMore());
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<ShowAllProductsBloc>();
    final completion = bloc.stream
        .skipWhile((state) => state.status != ShowAllProductsStatus.loading)
        .firstWhere(
          (state) =>
              state.status == ShowAllProductsStatus.success ||
              state.status == ShowAllProductsStatus.error,
        );
    bloc.add(const ShowAllProductsRefreshed());
    await completion;
  }

  @override
  Widget build(BuildContext context) {
    final results = BlocConsumer<ShowAllProductsBloc, ShowAllProductsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.status == ShowAllProductsStatus.loading ||
              current.status == ShowAllProductsStatus.success ||
              current.status == ShowAllProductsStatus.error),
      listener: (_, state) {
        if (state.status == ShowAllProductsStatus.loading &&
            state.items.isEmpty) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        } else if (state.status == ShowAllProductsStatus.success) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _maybeLoadMore();
            }
          });
        }
      },
      builder: (context, state) {
        if (state.status == ShowAllProductsStatus.loading &&
            state.items.isEmpty) {
          return _withStaticHeader(
            const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.primaryColor,
              ),
            ),
          );
        }
        if (state.status == ShowAllProductsStatus.error &&
            state.items.isEmpty) {
          return _withStaticHeader(
            ErrorState(
              onTap: () => context.read<ShowAllProductsBloc>().add(
                const ShowAllProductsRefreshed(),
              ),
            ),
          );
        }
        return _grid(state);
      },
    );

    if (!_isYakalar) {
      return Scaffold(appBar: _buildAppBar(), body: results);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: ColoredBox(
          color: AppPalette.of(context).surfaceAlt,
          child: results,
        ),
      ),
    );
  }

  Widget _withStaticHeader(Widget child) {
    if (!_isYakalar) {
      return child;
    }
    return Column(
      children: [
        _buildAppBar(),
        _SubcategoryChips(future: _subCategoriesFuture),
        Expanded(child: child),
      ],
    );
  }

  CustomAppBar _buildAppBar() => CustomAppBar(
    title: _name,
    showBackButton: true,
    titleWidget: _isYakalar ? _imageSearchButton() : null,
    actionButton: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showSortSheet(context),
          icon: AppIcon(
            Icons.filter_list,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        if (_isYakalar)
          IconButton(
            onPressed: () => context.push(AppRoutes.search),
            icon: AppIcon(
              Icons.search,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
          ),
      ],
    ),
  );

  Widget _grid(ShowAllProductsState state) {
    return RefreshIndicator(
      color: ColorConstants.primaryColor,
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          if (_isYakalar)
            SliverPersistentHeader(
              floating: true,
              delegate: _CollarsHeaderDelegate(
                child: Column(
                  children: [
                    _buildAppBar(),
                    _SubcategoryChips(future: _subCategoriesFuture),
                  ],
                ),
              ),
            ),
          if (state.items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(name: 'emptyData', type: EmptyStateType.text),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ProductCard(
                    product: state.items[index],
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                  ),
                  childCount: state.items.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 9 / 16,
                ),
              ),
            ),
          if (state.status == ShowAllProductsStatus.loadingMore)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 72,
                child: Center(
                  child: CircularProgressIndicator(
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ),
            )
          else if (state.status == ShowAllProductsStatus.loadMoreError)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => context.read<ShowAllProductsBloc>().add(
                      const ShowAllProductsLoadMore(),
                    ),
                    icon: const AppIcon(Icons.refresh, size: 18),
                    label: Text('noConnection3'.tr),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext outerContext) {
    final bloc = outerContext.read<ShowAllProductsBloc>();
    showModalBottomSheet<void>(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: AppPalette.of(outerContext).surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final palette = AppPalette.of(sheetContext);
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ColorConstants.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const AppIcon(
                            Icons.filter_list,
                            size: 22,
                            color: ColorConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'sort'.tr,
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: MaterialLocalizations.of(sheetContext)
                              .closeButtonTooltip,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: palette.surfaceAlt,
                            fixedSize: const Size(40, 40),
                          ),
                          icon: AppIcon(
                            Icons.close_rounded,
                            size: 18,
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    for (
                      var index = 0;
                      index < ListConstants.sortData.length;
                      index++
                    ) ...[
                      _SortOptionTile(
                        label: '${ListConstants.sortData[index]['name']}'.tr,
                        icon: _sortIcons[index],
                        selected: index == bloc.state.sortRadioIndex,
                        onTap: () {
                          bloc.add(
                            ShowAllProductsSortChanged(
                              sortColumn:
                                  ListConstants.sortData[index]['sort_column']
                                      as String,
                              radioIndex: index,
                            ),
                          );
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      if (index < ListConstants.sortData.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _imageSearchButton() {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.searchByImage),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppPalette.of(context).surface,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              Icons.camera_alt_outlined,
              color: ColorConstants.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'search_by_image'.tr,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: ColorConstants.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollarsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CollarsHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => kToolbarHeight + 64;

  @override
  double get maxExtent => kToolbarHeight + 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _CollarsHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = ColorConstants.primaryColor;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.10) : palette.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? accent : palette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: selected ? accent : palette.muted),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accent : Colors.transparent,
                    border: selected
                        ? null
                        : Border.all(color: palette.muted, width: 1.5),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubcategoryChips extends StatelessWidget {
  const _SubcategoryChips({required this.future});
  final Future<Result<List<FilterElementModel>>>? future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<FilterElementModel>>>(
      future: future,
      builder: (context, snapshot) {
        final subs = switch (snapshot.data) {
          Success<List<FilterElementModel>>(:final data) => data,
          _ => const <FilterElementModel>[],
        };
        return BlocBuilder<ShowAllProductsBloc, ShowAllProductsState>(
          buildWhen: (prev, curr) =>
              prev.selectedSubIndex != curr.selectedSubIndex,
          builder: (context, state) {
            final palette = AppPalette.of(context);
            return SizedBox(
              height: 64,
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: subs.length + 1,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final subIndex = index - 1;
                  final selected = state.selectedSubIndex == subIndex;
                  final label = index == 0
                      ? 'filter_all'.tr
                      : (subs[subIndex].name ?? '');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Semantics(
                      selected: selected,
                      button: true,
                      inMutuallyExclusiveGroup: true,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: selected
                              ? ColorConstants.primaryColor.withValues(
                                  alpha: 0.11,
                                )
                              : palette.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: selected
                                ? ColorConstants.primaryColor.withValues(
                                    alpha: 0.55,
                                  )
                                : palette.border,
                            width: selected ? 1.3 : 1,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: ColorConstants.primaryColor
                                        .withValues(alpha: 0.09),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: selected
                                ? null
                                : () => context.read<ShowAllProductsBloc>().add(
                                    ShowAllProductsFilterChanged(
                                      subCategoryId: index == 0
                                          ? 0
                                          : (subs[subIndex].id ?? 0),
                                      subCategoryIndex: subIndex,
                                    ),
                                  ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 180,
                                  ),
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selected
                                          ? ColorConstants.primaryColor
                                          : palette.text,
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
