part of 'show_all_products_bloc.dart';

sealed class ShowAllProductsEvent {
  const ShowAllProductsEvent();
}

final class ShowAllProductsInitialized extends ShowAllProductsEvent {
  const ShowAllProductsInitialized({
    required this.categoryId,
    this.subCategoryId,
    this.subCategoryIndex,
  });
  final int categoryId;
  final int? subCategoryId;
  final int? subCategoryIndex;
}

final class ShowAllProductsRefreshed extends ShowAllProductsEvent {
  const ShowAllProductsRefreshed();
}

final class ShowAllProductsLoadMore extends ShowAllProductsEvent {
  const ShowAllProductsLoadMore();
}

final class ShowAllProductsSortChanged extends ShowAllProductsEvent {
  const ShowAllProductsSortChanged({
    required this.sortColumn,
    required this.radioIndex,
  });
  final String sortColumn;
  final int radioIndex;
}

final class ShowAllProductsFilterChanged extends ShowAllProductsEvent {
  const ShowAllProductsFilterChanged({
    required this.subCategoryId,
    required this.subCategoryIndex,
  });
  final int subCategoryId;
  final int subCategoryIndex;
}
