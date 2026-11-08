import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.categoryName,
    required this.downloadable,
    this.quantity = 0,
    this.videoUrl,
    this.barcode,
    this.description,
    this.views,
    this.createdAt = '',
    this.images = const [],
  });

  final int id;
  final String name;
  final String price;
  final String image;
  final String categoryName;
  final bool downloadable;
  final int quantity;
  final String? videoUrl;
  final String? barcode;
  final String? description;
  final String? views;
  final String createdAt;
  final List<String> images;

  ProductEntity copyWith({int? quantity}) => ProductEntity(
    id: id,
    name: name,
    price: price,
    image: image,
    categoryName: categoryName,
    downloadable: downloadable,
    quantity: quantity ?? this.quantity,
    videoUrl: videoUrl,
    barcode: barcode,
    description: description,
    views: views,
    createdAt: createdAt,
    images: images,
  );

  @override
  List<Object?> get props => [id, name, price, quantity];
}
