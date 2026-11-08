import '../../../../core/utils/safe_parser.dart';
import '../../domain/entities/cart_item_entity.dart';

class CartItemModel {
  const CartItemModel({
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

  factory CartItemModel.fromJson(Map<dynamic, dynamic> json) => CartItemModel(
    id: SafeParser.asInt(json['id']),
    name: SafeParser.asString(json['name']),
    price: SafeParser.asString(json['price'], fallback: '0'),
    image: SafeParser.asString(json['image']),
    quantity: SafeParser.asInt(json['quantity'], fallback: 1),
    categoryName: SafeParser.asString(json['categoryName']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'image': image,
    'quantity': quantity,
    'categoryName': categoryName,
  };

  CartItemEntity toEntity() => CartItemEntity(
    id: id,
    name: name,
    price: price,
    image: image,
    quantity: quantity,
    categoryName: categoryName,
  );

  factory CartItemModel.fromEntity(CartItemEntity e) => CartItemModel(
    id: e.id,
    name: e.name,
    price: e.price,
    image: e.image,
    quantity: e.quantity,
    categoryName: e.categoryName,
  );
}
