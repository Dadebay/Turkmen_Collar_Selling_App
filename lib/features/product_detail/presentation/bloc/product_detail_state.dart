part of 'product_detail_bloc.dart';

sealed class ProductDetailState {
  const ProductDetailState();
}

final class ProductDetailInitial extends ProductDetailState {}

final class ProductDetailLoading extends ProductDetailState {}

final class ProductDetailLoaded extends ProductDetailState {
  const ProductDetailLoaded(this.product);
  final ProductEntity product;
}

final class ProductDetailCollarLoaded extends ProductDetailState {
  const ProductDetailCollarLoaded(this.collar);
  final CollarEntity collar;
}

final class ProductDetailError extends ProductDetailState {
  const ProductDetailError(this.message);
  final String message;
}
