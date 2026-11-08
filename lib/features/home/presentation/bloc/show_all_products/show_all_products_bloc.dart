import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/result/result.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/home_repository.dart';

part 'show_all_products_event.dart';
part 'show_all_products_state.dart';

class ShowAllProductsBloc
    extends Bloc<ShowAllProductsEvent, ShowAllProductsState> {
  ShowAllProductsBloc(this._repository) : super(const ShowAllProductsState()) {
    on<ShowAllProductsInitialized>(_onInitialized);
    on<ShowAllProductsRefreshed>(_onRefreshed);
    on<ShowAllProductsLoadMore>(_onLoadMore);
    on<ShowAllProductsSortChanged>(_onSortChanged);
    on<ShowAllProductsFilterChanged>(_onFilterChanged);
  }

  final HomeRepository _repository;
  static const int _limit = 10;
  int _generation = 0;

  Future<void> _onInitialized(
    ShowAllProductsInitialized event,
    Emitter<ShowAllProductsState> emit,
  ) async {
    emit(
      state.copyWith(
        categoryId: event.categoryId,
        subCategoryId: event.subCategoryId ?? 0,
        selectedSubIndex: event.subCategoryIndex ?? -1,
        page: 1,
        items: const [],
        reachedEnd: false,
        status: ShowAllProductsStatus.loading,
      ),
    );
    await _fetchFirstPage(emit);
  }

  Future<void> _onRefreshed(
    ShowAllProductsRefreshed event,
    Emitter<ShowAllProductsState> emit,
  ) async {
    emit(
      state.copyWith(
        page: 1,
        items: const [],
        sortColumn: '',
        subCategoryId: 0,
        selectedSubIndex: -1,
        sortRadioIndex: 0,
        reachedEnd: false,
        status: ShowAllProductsStatus.loading,
      ),
    );
    await _fetchFirstPage(emit);
  }

  Future<void> _onLoadMore(
    ShowAllProductsLoadMore event,
    Emitter<ShowAllProductsState> emit,
  ) async {
    if ((state.status != ShowAllProductsStatus.success &&
            state.status != ShowAllProductsStatus.loadMoreError) ||
        state.items.isEmpty ||
        state.reachedEnd) {
      return;
    }
    final previous = state;
    final nextPage = previous.page + 1;
    final generation = _generation;
    emit(previous.copyWith(status: ShowAllProductsStatus.loadingMore));

    final result = await _repository.getCategoryProducts(
      categoryId: previous.categoryId,
      params: _params(previous, nextPage),
    );
    if (emit.isDone || generation != _generation) {
      return;
    }

    result.when(
      success: (list) {
        final seenIds = state.items.map((item) => item.id).toSet();
        final newItems = list
            .where((item) => item.id == 0 || seenIds.add(item.id))
            .toList();
        emit(
          state.copyWith(
            page: nextPage,
            items: [...state.items, ...newItems],
            reachedEnd: list.length < _limit || newItems.isEmpty,
            status: ShowAllProductsStatus.success,
          ),
        );
      },
      failure: (_) {
        emit(state.copyWith(status: ShowAllProductsStatus.loadMoreError));
      },
    );
  }

  Future<void> _onSortChanged(
    ShowAllProductsSortChanged event,
    Emitter<ShowAllProductsState> emit,
  ) async {
    emit(
      state.copyWith(
        sortColumn: event.sortColumn,
        sortRadioIndex: event.radioIndex,
        page: 1,
        items: const [],
        reachedEnd: false,
        status: ShowAllProductsStatus.loading,
      ),
    );
    await _fetchFirstPage(emit);
  }

  Future<void> _onFilterChanged(
    ShowAllProductsFilterChanged event,
    Emitter<ShowAllProductsState> emit,
  ) async {
    emit(
      state.copyWith(
        subCategoryId: event.subCategoryId,
        selectedSubIndex: event.subCategoryIndex,
        page: 1,
        items: const [],
        reachedEnd: false,
        status: ShowAllProductsStatus.loading,
      ),
    );
    await _fetchFirstPage(emit);
  }

  Future<void> _fetchFirstPage(Emitter<ShowAllProductsState> emit) async {
    final generation = ++_generation;
    final requestState = state;
    final result = await _repository.getCategoryProducts(
      categoryId: requestState.categoryId,
      params: _params(requestState, 1),
    );
    if (emit.isDone || generation != _generation) {
      return;
    }
    result.when(
      success: (list) => emit(
        state.copyWith(
          page: 1,
          items: list,
          reachedEnd: list.length < _limit,
          status: ShowAllProductsStatus.success,
        ),
      ),
      failure: (_) => emit(state.copyWith(status: ShowAllProductsStatus.error)),
    );
  }

  Map<String, String> _params(ShowAllProductsState requestState, int page) => {
    'page': '$page',
    'limit': '$_limit',
    'sort_by': requestState.sortColumn,
    'min': '',
    'max': '',
    'tag': requestState.subCategoryId == 0
        ? ''
        : '${requestState.subCategoryId}',
  };
}
