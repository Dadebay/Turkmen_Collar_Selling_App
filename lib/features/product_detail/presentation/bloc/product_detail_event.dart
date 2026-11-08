part of 'product_detail_bloc.dart';

sealed class ProductDetailEvent {
  const ProductDetailEvent();
}

final class ProductDetailLoadRequested extends ProductDetailEvent {
  const ProductDetailLoadRequested({required this.id, required this.isCollar});
  final int id;
  final bool isCollar;
}
