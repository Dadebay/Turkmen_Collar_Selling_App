part of 'search_bloc.dart';

sealed class SearchEvent {
  const SearchEvent();
}

final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);
  final String query;
}

final class SearchCleared extends SearchEvent {
  const SearchCleared();
}
