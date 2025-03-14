// ignore_for_file: unnecessary_null_comparison

class ProductModel {
  final int id;
  final int? quantity;
  final String price;
  final String createdAt;
  final String name;
  final String image;
  final String categoryName;
  final bool downloadable;
  final String? videoURL;

  ProductModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.image,
    required this.price,
    required this.categoryName,
    required this.downloadable,
    this.videoURL,
    this.quantity,
  });

  factory ProductModel.fromJson(Map<dynamic, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      name: json['name']?.toString() ?? '',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      image: json['image'] ?? json['images'] ?? '',
      price: json['price']?.toString() ?? '0',
      categoryName: json['category_name']?.toString() ?? '',
      downloadable: json['downloadable'] ?? false,
      videoURL: json['video_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'createdAt': createdAt,
      'categoryName': categoryName,
      'downloadable': downloadable,
      'videoURL': videoURL,
      'quantity': quantity,
    };
  }
}
