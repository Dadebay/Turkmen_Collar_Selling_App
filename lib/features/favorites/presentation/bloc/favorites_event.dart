part of 'favorites_bloc.dart';

sealed class FavoritesEvent {
  const FavoritesEvent();
}

final class FavoritesLoadRequested extends FavoritesEvent {
  const FavoritesLoadRequested();
}

final class FavoritesToggleRequested extends FavoritesEvent {
  const FavoritesToggleRequested({required this.id, required this.isCollar});
  final int id;
  final bool isCollar;
}
