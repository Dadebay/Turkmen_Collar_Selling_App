part of 'favorites_bloc.dart';

/// One-shot result of the most recent favorite toggle, carried on
/// [FavoritesLoaded] so a listener can show "added / removed" feedback without
/// affecting the heart icon the [FavoritesLoaded] data drives.
enum FavoritesToggleResult { added, removed, addFailed, removeFailed }

sealed class FavoritesState {
  const FavoritesState();
}

final class FavoritesInitial extends FavoritesState {}

final class FavoritesLoading extends FavoritesState {}

final class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded({
    required this.products,
    required this.collars,
    required this.favProductIds,
    required this.favCollarIds,
    this.lastToggle,
  });
  final List<ProductEntity> products;
  final List<ProductEntity> collars;
  final List<int> favProductIds;
  final List<int> favCollarIds;

  /// Non-null only on the state emitted right after a toggle. Every emit is a
  /// new [FavoritesLoaded] instance (no equality override), so a `BlocListener`
  /// keyed on `lastToggle != null` fires once per action.
  final FavoritesToggleResult? lastToggle;

  bool isFav(int id, {required bool isCollar}) =>
      isCollar ? favCollarIds.contains(id) : favProductIds.contains(id);
}

final class FavoritesError extends FavoritesState {
  const FavoritesError(this.message);
  final String message;
}
