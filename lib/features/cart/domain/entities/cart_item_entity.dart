import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  const CartItemEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
    required this.categoryName,
  });

  final int id;
  final String name;
  final String price;
  final String image;
  final int quantity;
  final String categoryName;

  CartItemEntity copyWith({int? quantity}) => CartItemEntity(
    id: id,
    name: name,
    price: price,
    image: image,
    quantity: quantity ?? this.quantity,
    categoryName: categoryName,
  );

  @override
  List<Object?> get props => [id, quantity];
}
