import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yaka2/core/icons/iconly_icons.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/cards/product_card.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../features/home/domain/entities/product_entity.dart';
import '../../../../features/home/domain/repositories/home_repository.dart';
import '../../../../injection_container.dart';
import '../bloc/search_bloc.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late Future<Result<List<ProductEntity>>> _suggestionsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _suggestionsFuture = _loadSuggestions();
  }

  Future<Result<List<ProductEntity>>> _loadSuggestions() async {
    final result = await sl<HomeRepository>().getCollars();
    return result.when(
      success: (collars) {
        final shuffled = [...collars]..shuffle(Random());
        final products = shuffled.take(12).map((collar) {
          final images = collar.images
              .map((image) => image.toString())
              .toList();
          return ProductEntity(
            id: collar.id ?? 0,
            name: collar.name ?? '',
            price: (collar.price ?? 0).toString(),
            image: images.isEmpty ? '' : images.first,
            images: images,
            categoryName: 'collars'.tr,
            downloadable: true,
            description: collar.description,
            views: collar.views?.toString(),
            createdAt: collar.createdAt ?? '',
          );
        }).toList();
        return Success<List<ProductEntity>>(products);
      },
      failure: (failure) => Failure<List<ProductEntity>>(failure),
    );
  }

  void _onQueryChanged(String value) {
    final query = value.trim();
    setState(() => _query = query);
    if (query.isEmpty) {
      context.read<SearchBloc>().add(const SearchCleared());
    } else {
      context.read<SearchBloc>().add(SearchQueryChanged(query));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'search',
        showBackButton: true,
        titleWidget: _searchField(context),
      ),
      body: _query.isEmpty ? _suggestions() : _results(),
    );
  }

  Widget _searchField(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? palette.surfaceAlt : palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: palette.border) : null,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onQueryChanged,
        textInputAction: TextInputAction.search,
        cursorColor: ColorConstants.primaryColor,
        style: TextStyle(color: palette.text, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'search'.tr,
          hintStyle: TextStyle(color: palette.muted, fontSize: 15),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 42,
          ),
          prefixIcon: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AppIcon(IconlyLight.search, size: 20, color: palette.muted),
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: MaterialLocalizations.of(context)
                      .deleteButtonTooltip,
                  onPressed: () {
                    _controller.clear();
                    _onQueryChanged('');
                    _focusNode.requestFocus();
                  },
                  icon: AppIcon(
                    Icons.close_rounded,
                    size: 18,
                    color: palette.muted,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _suggestions() {
    return FutureBuilder<Result<List<ProductEntity>>>(
      future: _suggestionsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorConstants.primaryColor,
            ),
          );
        }
        final result = snapshot.data!;
        if (result is Failure<List<ProductEntity>>) {
          return ErrorState(
            onTap: () => setState(() {
              _suggestionsFuture = _loadSuggestions();
            }),
          );
        }
        final products = (result as Success<List<ProductEntity>>).data;
        if (products.isEmpty) {
          return const EmptyState(
            name: 'emptyData',
            type: EmptyStateType.lottie,
          );
        }
        return _productGrid(products, title: 'randomCollars'.tr);
      },
    );
  }

  Widget _results() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading || state is SearchInitial) {
          return const Center(
            child: CircularProgressIndicator(
              color: ColorConstants.primaryColor,
            ),
          );
        }
        if (state is SearchError) {
          return ErrorState(
            onTap: () =>
                context.read<SearchBloc>().add(SearchQueryChanged(_query)),
          );
        }
        final products = (state as SearchLoaded).results;
        if (products.isEmpty) {
          return const EmptyState(
            name: 'no_results_found',
            type: EmptyStateType.lottie,
          );
        }
        return _productGrid(products, title: 'search_results'.tr);
      },
    );
  }

  Widget _productGrid(List<ProductEntity> products, {required String title}) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 9 / 16,
            ),
            itemBuilder: (context, index) =>
                ProductCard(product: products[index]),
          ),
        ),
      ],
    );
  }
}
