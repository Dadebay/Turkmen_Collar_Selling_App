import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/color_constants.dart';
import '../../../../core/widgets/error_state.dart';
import '../bloc/home_bloc.dart';
import '../widgets/banners_section.dart';
import '../widgets/categories_section.dart';
import '../widgets/products_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeLoadRequested());
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<HomeBloc>();
    final completed = bloc.stream.firstWhere(
      (state) => state is HomeLoaded || state is HomeError,
    );
    if (bloc.state is! HomeLoading) {
      bloc.add(const HomeRefreshRequested());
    }
    await completed;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: ColorConstants.primaryColor,
      onRefresh: _onRefresh,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const BannersSection(),
              const CategoriesSection(),
              if (state is HomeLoading || state is HomeInitial)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                ),
              if (state is HomeError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: ErrorState(
                    onTap: () => context.read<HomeBloc>().add(
                      const HomeRefreshRequested(),
                    ),
                  ),
                ),
              if (state is HomeLoaded) ...[
                // if (state.collars.isNotEmpty)
                //   ProductsSection(
                //     titleKey: 'collars',
                //     products: state.collars
                //         .map(
                //           (c) => ProductEntity(
                //             id: c.id ?? 0,
                //             name: c.name ?? '',
                //             price: (c.price ?? 0).toString(),
                //             image: c.images.isNotEmpty
                //                 ? c.images.first.toString()
                //                 : '',
                //             categoryName: 'Ýakalar',
                //             downloadable: true,
                //             createdAt: c.createdAt ?? '',
                //           ),
                //         )
                //         .toList(),
                //   ),
                if (state.clothes.isNotEmpty)
                  ProductsSection(
                    titleKey: 'womenClothes',
                    products: state.clothes,
                  ),
                if (state.goods.isNotEmpty)
                  ProductsSection(
                    titleKey: 'listview_goods',
                    products: state.goods,
                  ),
                if (state.machines.isNotEmpty)
                  ProductsSection(
                    titleKey: 'machines',
                    products: state.machines,
                    isMachine: true,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
