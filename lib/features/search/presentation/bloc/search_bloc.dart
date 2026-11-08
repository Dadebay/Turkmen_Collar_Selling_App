import 'package:bloc/bloc.dart';

import '../../../../core/result/result.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../../home/domain/repositories/home_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._repository) : super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchCleared>(_onCleared);
  }

  final HomeRepository _repository;
  int _requestVersion = 0;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final version = ++_requestVersion;
    if (event.query.trim().isEmpty) {
      emit(const SearchInitial());
      return;
    }
    emit(const SearchLoading());
    final result = await _repository.searchCollars(query: event.query.trim());
    if (version != _requestVersion) {
      return;
    }
    switch (result) {
      case Success(:final data):
        emit(SearchLoaded(data));
      case Failure(:final failure):
        emit(SearchError(failure.message));
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _requestVersion++;
    emit(const SearchInitial());
  }
}
