// ignore_for_file: always_put_control_body_on_new_line
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/border_radius_constants.dart';
import '../../../../core/constants/widget_sizes.dart';
import '../../../../core/result/result.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/widgets/loading.dart';
import '../../../../core/widgets/mini_category_loading.dart';
import '../../../../core/widgets/no_image.dart';
import '../../../../features/user_profile/data/datasources/profile_meta_remote_data_source.dart';
import '../../../../features/user_profile/data/models/meta_models.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/home_bloc.dart';

class _CarouselItem {
  _CarouselItem({required this.name, required this.onTap, this.image});

  final String? image;
  final String name;
  final VoidCallback onTap;
}

class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  late Future<Result<List<FilterElementModel>>> _filterElementsFuture;

  @override
  void initState() {
    super.initState();
    _filterElementsFuture = sl<ProfileMetaRemoteDataSource>()
        .getFilterElements();
  }

  Widget _buildCarousel(List<_CarouselItem> items, BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    if (items.length <= 4) {
      return SizedBox(
        height: WidgetSizes.size300.value,
        child: _buildCategoryGrid(items, 0, context),
      );
    }
    return SizedBox(
      height: WidgetSizes.size300.value,
      child: LayoutBuilder(
        builder: (context, constraints) => _ContinuousCategoryGrid(
          key: ValueKey('${(items.length / 4).ceil()}-${constraints.maxWidth}'),
          items: items,
          width: constraints.maxWidth,
          pageBuilder: (context, pageIndex) =>
              _buildCategoryGrid(items, pageIndex, context),
        ),
      ),
    );
  }

  Widget _buildYakalarBanner(CategoryEntity category, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.showAllProductsPath(category.id.toString()),
        extra: category,
      ),
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: CachedNetworkImage(
          fadeInCurve: Curves.ease,
          imageUrl: category.image,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: imageProvider,
                alignment: Alignment.topCenter,
                fit: BoxFit.fill,
              ),
            ),
          ),
          placeholder: (context, url) => const Loading(),
          errorWidget: (context, url, error) => const NoImage(),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    List<_CarouselItem> items,
    int pageIndex,
    BuildContext context,
  ) {
    final startIndex = pageIndex * 4;
    return Column(
      children: List.generate(2, (rowIndex) {
        return Expanded(
          child: Row(
            children: List.generate(2, (colIndex) {
              final itemIndex = startIndex + (rowIndex * 2) + colIndex;
              if (itemIndex >= items.length) {
                return Expanded(child: Container());
              }
              final item = items[itemIndex];
              return Expanded(
                child: GestureDetector(
                  onTap: item.onTap,
                  child: Padding(
                    padding: context.padding.low,
                    child: (item.image != null && item.image!.isNotEmpty)
                        ? CachedNetworkImage(
                            fadeInCurve: Curves.ease,
                            imageUrl: item.image!,
                            imageBuilder: (context, imageProvider) => Container(
                              padding: EdgeInsets.zero,
                              width: MediaQuery.sizeOf(context).width,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius:
                                    CustomBorderRadius.lowBorderRadius,
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                            placeholder: (context, url) => const Loading(),
                            errorWidget: (context, url, error) =>
                                Text(item.name),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: AppPalette.of(context).muted
                                  .withOpacity(.2),
                              borderRadius: CustomBorderRadius.lowBorderRadius,
                            ),
                            child: Center(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  color: AppPalette.of(context).text,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading || state is HomeInitial) {
          return const MiniCategoryLoading();
        }
        if (state is! HomeLoaded || state.categories.isEmpty) {
          return const SizedBox.shrink();
        }
        final mainCategories = state.categories;
        final yakalar = mainCategories.firstWhere(
          (cat) => cat.name == 'Ýakalar',
          orElse: () => mainCategories.first,
        );

        return FutureBuilder<Result<List<FilterElementModel>>>(
          future: _filterElementsFuture,
          builder: (context, snapshot) {
            final subCategories =
                (snapshot.data is Success<List<FilterElementModel>>)
                ? (snapshot.data as Success<List<FilterElementModel>>).data
                : const <FilterElementModel>[];

            final items = <_CarouselItem>[
              for (final cat in mainCategories)
                _CarouselItem(
                  name: cat.name,
                  image: cat.image,
                  onTap: () => context.push(
                    AppRoutes.showAllProductsPath(cat.id.toString()),
                    extra: cat,
                  ),
                ),
              for (var i = 0; i < subCategories.length; i++)
                _CarouselItem(
                  name: subCategories[i].name ?? '',
                  image: subCategories[i].image,
                  onTap: () => context.push(
                    AppRoutes.showAllProductsPath(
                      yakalar.id.toString(),
                      subCatId: subCategories[i].id,
                      subCatIndex: i,
                    ),
                    extra: yakalar,
                  ),
                ),
            ];

            return Wrap(
              children: [
                _buildCarousel(items, context),
                _buildYakalarBanner(yakalar, context),
              ],
            );
          },
        );
      },
    );
  }
}

class _ContinuousCategoryGrid extends StatefulWidget {
  const _ContinuousCategoryGrid({
    required this.items,
    required this.width,
    required this.pageBuilder,
    super.key,
  });

  final List<_CarouselItem> items;
  final double width;
  final Widget Function(BuildContext, int) pageBuilder;

  @override
  State<_ContinuousCategoryGrid> createState() =>
      _ContinuousCategoryGridState();
}

class _ContinuousCategoryGridState extends State<_ContinuousCategoryGrid>
    with SingleTickerProviderStateMixin {
  static const double _pixelsPerSecond = 18;
  static const int _middleCycle = 50;
  static const int _cycleCount = 101;

  late final ScrollController _scrollController;
  late final Ticker _ticker;
  Duration? _lastElapsed;
  bool _pointerDown = false;
  bool _userScrolling = false;

  int get _pageCount => (widget.items.length / 4).ceil();
  double get _cycleWidth => _pageCount * widget.width;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _middleCycle * _cycleWidth,
    );
    _ticker = createTicker(_advance)..start();
  }

  void _advance(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null ||
        _pageCount <= 1 ||
        _pointerDown ||
        _userScrolling ||
        !_scrollController.hasClients ||
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context)) {
      return;
    }

    final seconds =
        (elapsed - previous).inMicroseconds.clamp(0, 50000) /
        Duration.microsecondsPerSecond;
    final current = _scrollController.offset;
    final next =
        (_middleCycle * _cycleWidth) +
        ((current + seconds * _pixelsPerSecond) % _cycleWidth);
    _scrollController.jumpTo(next);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth != 0) return false;
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _userScrolling = true;
        } else if (notification is ScrollEndNotification) {
          _userScrolling = false;
        }
        return false;
      },
      child: Listener(
        onPointerDown: (_) => _pointerDown = true,
        onPointerUp: (_) => _pointerDown = false,
        onPointerCancel: (_) => _pointerDown = false,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemExtent: widget.width,
          itemCount: _pageCount * _cycleCount,
          itemBuilder: (context, index) =>
              widget.pageBuilder(context, index % _pageCount),
        ),
      ),
    );
  }
}
