part of 'home_bloc.dart';

sealed class HomeState {
  const HomeState();
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.banners,
    required this.categories,
    required this.machines,
    required this.clothes,
    required this.collars,
    required this.goods,
  });

  final List<BannerEntity> banners;
  final List<CategoryEntity> categories;
  final List<ProductEntity> machines;
  final List<ProductEntity> clothes;
  final List<CollarEntity> collars;
  final List<ProductEntity> goods;
}

final class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
}
