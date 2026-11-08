part of 'search_bloc.dart';

sealed class SearchState {
  const SearchState();
}

final class SearchInitial extends SearchState {
  const SearchInitial();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

final class SearchLoaded extends SearchState {
  const SearchLoaded(this.results);
  final List<ProductEntity> results;
}

final class SearchError extends SearchState {
  const SearchError(this.message);
  final String message;
}
