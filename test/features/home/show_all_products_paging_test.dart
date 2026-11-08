import 'package:flutter_test/flutter_test.dart';
import 'package:yaka2/core/result/result.dart';
import 'package:yaka2/features/home/domain/entities/product_entity.dart';
import 'package:yaka2/features/home/domain/repositories/home_repository.dart';
import 'package:yaka2/features/home/presentation/bloc/show_all_products/show_all_products_bloc.dart';

void main() {
  test('loads pages 2 and 3 in order and stops at the last page', () async {
    final repository = _PagingRepository();
    final bloc = ShowAllProductsBloc(repository);
    addTearDown(bloc.close);

    final firstPage = bloc.stream.firstWhere(
      (state) =>
          state.status == ShowAllProductsStatus.success && state.page == 1,
    );
    bloc.add(const ShowAllProductsInitialized(categoryId: 7));
    expect((await firstPage).items.length, 10);

    final secondPage = bloc.stream.firstWhere(
      (state) =>
          state.status == ShowAllProductsStatus.success && state.page == 2,
    );
    bloc.add(const ShowAllProductsLoadMore());
    expect((await secondPage).items.length, 20);

    final thirdPage = bloc.stream.firstWhere(
      (state) =>
          state.status == ShowAllProductsStatus.success && state.page == 3,
    );
    bloc.add(const ShowAllProductsLoadMore());
    final finalState = await thirdPage;
    expect(finalState.items.length, 23);
    expect(finalState.reachedEnd, isTrue);
    expect(repository.pagesRequested, [1, 2, 3]);

    bloc.add(const ShowAllProductsLoadMore());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repository.pagesRequested, [1, 2, 3]);
  });

  test('a failed next page keeps the current page for retry', () async {
    final repository = _PagingRepository(failSecondPage: true);
    final bloc = ShowAllProductsBloc(repository);
    addTearDown(bloc.close);

    final firstPage = bloc.stream.firstWhere(
      (state) =>
          state.status == ShowAllProductsStatus.success && state.page == 1,
    );
    bloc.add(const ShowAllProductsInitialized(categoryId: 7));
    await firstPage;

    final failedLoad = bloc.stream.firstWhere(
      (state) =>
          state.status == ShowAllProductsStatus.loadMoreError &&
          state.page == 1 &&
          repository.pagesRequested.length == 2,
    );
    bloc.add(const ShowAllProductsLoadMore());
    final state = await failedLoad;
    expect(state.items.length, 10);
    expect(state.reachedEnd, isFalse);
    expect(repository.pagesRequested, [1, 2]);

    final retriedLoad = bloc.stream.firstWhere(
      (state) =>
          state.status == ShowAllProductsStatus.loadMoreError &&
          repository.pagesRequested.length == 3,
    );
    bloc.add(const ShowAllProductsLoadMore());
    await retriedLoad;
    expect(repository.pagesRequested, [1, 2, 2]);
  });
}

class _PagingRepository implements HomeRepository {
  _PagingRepository({this.failSecondPage = false});

  final bool failSecondPage;
  final List<int> pagesRequested = [];

  @override
  Future<Result<List<ProductEntity>>> getCategoryProducts({
    required int categoryId,
    required Map<String, String> params,
  }) async {
    final page = int.parse(params['page']!);
    pagesRequested.add(page);
    if (page == 2 && failSecondPage) {
      return const Failure(NetworkFailure());
    }
    final count = page == 3 ? 3 : 10;
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
