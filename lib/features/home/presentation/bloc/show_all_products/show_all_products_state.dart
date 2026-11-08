part of 'show_all_products_bloc.dart';

enum ShowAllProductsStatus {
  idle,
  loading,
  loadingMore,
  loadMoreError,
  success,
  error,
}

class ShowAllProductsState {
  const ShowAllProductsState({
    this.categoryId = 0,
    this.items = const [],
    this.page = 1,
    this.subCategoryId = 0,
    this.selectedSubIndex = -1,
    this.sortColumn = '',
    this.sortRadioIndex = 0,
    this.status = ShowAllProductsStatus.idle,
    this.reachedEnd = false,
  });

  final int categoryId;
  final List<ProductEntity> items;
  final int page;
  final int subCategoryId;
  final int selectedSubIndex;
  final String sortColumn;
  final int sortRadioIndex;
  final ShowAllProductsStatus status;
  final bool reachedEnd;

  ShowAllProductsState copyWith({
    int? categoryId,
    List<ProductEntity>? items,
    int? page,
    int? subCategoryId,
    int? selectedSubIndex,
    String? sortColumn,
    int? sortRadioIndex,
    ShowAllProductsStatus? status,
    bool? reachedEnd,
  }) {
    return ShowAllProductsState(
      categoryId: categoryId ?? this.categoryId,
      items: items ?? this.items,
      page: page ?? this.page,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      selectedSubIndex: selectedSubIndex ?? this.selectedSubIndex,
      sortColumn: sortColumn ?? this.sortColumn,
      sortRadioIndex: sortRadioIndex ?? this.sortRadioIndex,
      status: status ?? this.status,
      reachedEnd: reachedEnd ?? this.reachedEnd,
    );
  }
}
