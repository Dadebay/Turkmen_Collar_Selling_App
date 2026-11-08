import '../../../../core/utils/safe_parser.dart';
import '../../domain/entities/product_entity.dart';

class ProductModel {
  const ProductModel({
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

  factory ProductModel.fromJson(Map<dynamic, dynamic> json) {
    final imgs = SafeParser.asStringList(json['images']);
    return ProductModel(
      id: SafeParser.asInt(json['id']),
      quantity: SafeParser.asInt(json['quantity']),
      name: SafeParser.asString(json['name']),
      createdAt: SafeParser.asString(json['created_at'] ?? json['createdAt']),
      image: imgs.isNotEmpty ? imgs.first : SafeParser.asString(json['image']),
      description: SafeParser.asStringOrNull(json['description']),
      barcode: SafeParser.asStringOrNull(json['barcode']),
      price: SafeParser.asString(json['price'], fallback: '0'),
      categoryName: SafeParser.asString(
        json['category_name'] ?? json['category'],
        fallback: 'kategoriya',
      ),
      downloadable: SafeParser.asBool(
        json['downloadable'],
        fallback: SafeParser.asInt(json['downloads']) == 0,
      ),
      videoUrl: SafeParser.asStringOrNull(json['video_url']),
      views: SafeParser.asString(json['views'], fallback: '0'),
      images: imgs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt,
    'image': image,
    'price': price,
    'categoryName': categoryName,
    'downloadable': downloadable,
    'videoURL': videoUrl,
    'quantity': quantity,
    'barcode': barcode,
    'description': description,
    'views': views,
    'images': images,
  };

  ProductEntity toEntity() => ProductEntity(
    id: id,
    name: name,
    price: price,
    image: image,
    categoryName: categoryName,
    downloadable: downloadable,
    quantity: quantity,
    videoUrl: videoUrl,
    barcode: barcode,
    description: description,
    views: views,
    createdAt: createdAt,
    images: images,
  );

  factory ProductModel.fromEntity(ProductEntity e) => ProductModel(
    id: e.id,
    name: e.name,
    price: e.price,
    image: e.image,
    categoryName: e.categoryName,
    downloadable: e.downloadable,
    quantity: e.quantity,
    videoUrl: e.videoUrl,
    barcode: e.barcode,
    description: e.description,
    views: e.views,
    createdAt: e.createdAt,
    images: e.images,
  );
}
