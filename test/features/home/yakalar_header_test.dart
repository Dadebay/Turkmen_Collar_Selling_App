import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/result/result.dart';
import 'package:yaka2/core/theme/app_themes.dart';
import 'package:yaka2/core/widgets/custom_app_bar.dart';
import 'package:yaka2/features/home/domain/entities/category_entity.dart';
import 'package:yaka2/features/home/domain/entities/product_entity.dart';
import 'package:yaka2/features/home/domain/repositories/home_repository.dart';
import 'package:yaka2/features/home/presentation/bloc/show_all_products/show_all_products_bloc.dart';
import 'package:yaka2/features/home/presentation/pages/show_all_products_page.dart';
import 'package:yaka2/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:yaka2/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:yaka2/features/payment/data/datasources/payment_status_remote_data_source.dart';
import 'package:yaka2/features/payment/presentation/bloc/payment_status_bloc.dart';
import 'package:yaka2/core/storage/local_storage.dart';
import 'package:yaka2/features/user_profile/data/datasources/profile_meta_remote_data_source.dart';
import 'package:yaka2/features/user_profile/data/models/meta_models.dart';
import 'package:yaka2/injection_container.dart';

void main() {
  testWidgets('Yakalar header and filters render without the paging footer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    final repository = _EmptyRepository();
    sl.registerFactory<ShowAllProductsBloc>(
      () => ShowAllProductsBloc(repository),
    );
    sl.registerSingleton<ProfileMetaRemoteDataSource>(_TagsSource());
    final favoritesBloc = FavoritesBloc(_FavoritesRepository());
    final paymentBloc = PaymentStatusBloc(
      remote: const PaymentStatusRemoteDataSource(
        baseUrl: 'https://example.com',
      ),
      storage: _TestStorage(),
    );
    addTearDown(() async {
      await favoritesBloc.close();
      await paymentBloc.close();
      await sl.unregister<ShowAllProductsBloc>();
      await sl.unregister<ProfileMetaRemoteDataSource>();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: favoritesBloc),
            BlocProvider.value(value: paymentBloc),
          ],
          child: const ShowAllProductsPage(
            category: 'Ýakalar',
            categoryEntity: CategoryEntity(
              id: 7,
              name: 'Ýakalar',
              image: '',
              isCollar: true,
              isMachine: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Ählisi'), findsOneWidget);
    expect(find.text('Dantel'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);

    expect(find.byType(SliverPersistentHeader), findsOneWidget);
    final header = find.byType(CustomAppBar);
    final firstChip = find
        .ancestor(
          of: find.text('Ählisi'),
          matching: find.byType(AnimatedContainer),
        )
        .first;
    expect(
      tester.getTopLeft(firstChip).dy - tester.getBottomLeft(header).dy,
      closeTo(10, 0.1),
    );
    final initialTop = tester.getTopLeft(header).dy;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    await gesture.moveBy(const Offset(0, -240));
    await tester.pump(const Duration(milliseconds: 250));
    expect(header, findsNothing);
    expect(repository.requestedPages, contains(2));

    await gesture.moveBy(const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 250));
    expect(header, findsOneWidget);
    expect(tester.getTopLeft(header).dy, closeTo(initialTop, 1));
    await gesture.up();
  });
}

class _TagsSource extends ProfileMetaRemoteDataSource {
  _TagsSource()
    : super(baseUrl: 'https://example.com', tokenProvider: _noToken);

  @override
  Future<Result<List<FilterElementModel>>> getFilterElements() async =>
      Success([FilterElementModel(id: 1, name: 'Dantel')]);
}

Future<String?> _noToken() async => null;

class _EmptyRepository implements HomeRepository {
  final requestedPages = <int>[];

  @override
  Future<Result<List<ProductEntity>>> getCategoryProducts({
    required int categoryId,
    required Map<String, String> params,
  }) async {
    final page = int.parse(params['page']!);
    requestedPages.add(page);
    final count = page == 1 ? 10 : 3;
    return Success(
      List.generate(count, (index) {
        final id = (page - 1) * 10 + index + 1;
        return ProductEntity(
          id: id,
          name: 'Yaka $id',
          price: '10',
          image: '',
          categoryName: 'Ýakalar',
          downloadable: true,
        );
      }),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FavoritesRepository implements FavoritesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestStorage extends LocalStorage {
  @override
  bool? get paymentDisabled => false;
}
