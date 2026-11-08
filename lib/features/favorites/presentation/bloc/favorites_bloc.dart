import 'package:bloc/bloc.dart';

import '../../../../core/result/result.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc(this._repository) : super(FavoritesInitial()) {
    on<FavoritesLoadRequested>(_onLoad);
    on<FavoritesToggleRequested>(_onToggle);
  }

  final FavoritesRepository _repository;

  Future<void> _onLoad(
    FavoritesLoadRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    final productsResult = await _repository.fetchFavProducts();
    final collarsResult = await _repository.fetchFavCollars();

    final products = switch (productsResult) {
      Success(:final data) => data,
      Failure() => <ProductEntity>[],
    };
    final collars = switch (collarsResult) {
      Success(:final data) => data,
      Failure() => <ProductEntity>[],
    };
    emit(
      FavoritesLoaded(
        products: products,
        collars: collars,
        favProductIds: products.map((e) => e.id).toList(),
        favCollarIds: collars.map((e) => e.id).toList(),
      ),
    );
  }

  Future<void> _onToggle(
    FavoritesToggleRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FavoritesLoaded) {
      return;
    }

    final isFav = event.isCollar
        ? currentState.favCollarIds.contains(event.id)
        : currentState.favProductIds.contains(event.id);

    Result<void> result;
    if (isFav) {
      result = await _repository.removeFavorite(
        id: event.id,
        isCollar: event.isCollar,
      );
    } else {
      result = await _repository.addFavorite(
        id: event.id,
        isCollar: event.isCollar,
      );
    }

    switch (result) {
      case Success():
        final newProductIds = event.isCollar
            ? currentState.favProductIds
            : isFav
            ? currentState.favProductIds.where((e) => e != event.id).toList()
            : [...currentState.favProductIds, event.id];
        final newCollarIds = event.isCollar
            ? isFav
                  ? currentState.favCollarIds
                        .where((e) => e != event.id)
                        .toList()
                  : [...currentState.favCollarIds, event.id]
            : currentState.favCollarIds;

        final newProducts = event.isCollar
            ? currentState.products
            : isFav
            ? currentState.products.where((p) => p.id != event.id).toList()
            : currentState.products;
        final newCollars = event.isCollar
            ? isFav
                  ? currentState.collars.where((p) => p.id != event.id).toList()
                  : currentState.collars
            : currentState.collars;

        emit(
          FavoritesLoaded(
            products: newProducts,
            collars: newCollars,
            favProductIds: newProductIds,
            favCollarIds: newCollarIds,
            lastToggle: isFav
                ? FavoritesToggleResult.removed
                : FavoritesToggleResult.added,
          ),
        );
      case Failure():
        // Toggle failed: re-emit the unchanged list (so the heart snaps back)
        // carrying a one-shot failure result to drive an error snackbar.
        emit(
          FavoritesLoaded(
            products: currentState.products,
            collars: currentState.collars,
            favProductIds: currentState.favProductIds,
            favCollarIds: currentState.favCollarIds,
            lastToggle: isFav
                ? FavoritesToggleResult.removeFailed
                : FavoritesToggleResult.addFailed,
          ),
        );
    }
  }
}
