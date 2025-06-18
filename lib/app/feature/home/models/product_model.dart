// ignore_for_file: unnecessary_null_comparison

class ProductModel {
  final int id;
  final int? quantity;
  final String price;
  final String createdAt;
  final String name;
  final String image;
  final String categoryName;
  bool downloadable;
  final String? videoURL;
  final String? barcode;
  final String? description;
  final String? views;
  final List<String>? images;

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
    this.images,
    this.barcode,
    this.views,
    this.description,
  });

  factory ProductModel.fromJson(Map<dynamic, dynamic> json) {
    List<String> images = [];

    if (json['images'] != null) {
      if (json['images'] is String) {
        images = [json['images']];
      } else if (json['images'] is List) {
        images = json['images'].map<String>((e) => e.toString()).toList();
      }
    }

    return ProductModel(
      id: json['id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      name: json['name']?.toString() ?? '',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      image: images.isNotEmpty ? images.first : (json['image']?.toString() ?? ''),
      description: json['description']?.toString() ?? 'null',
      barcode: json['barcode']?.toString() ?? 'null',
      price: json['price']?.toString() ?? '0',
      categoryName: json['category_name']?.toString() ?? json['category']?.toString() ?? 'kategoriya',
      downloadable: json['downloadable'] ?? json['downloads'] == 0 ? true : false,
      videoURL: json['video_url']?.toString() ?? '',
      views: json['views']?.toString() ?? '0',
      images: images.isNotEmpty ? images : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'image': image,
      'price': price,
      'categoryName': categoryName,
      'downloadable': downloadable,
      'videoURL': videoURL,
      'quantity': quantity,
      'barcode': barcode,
      'description': description,
      'views': views,
      'images': images ?? [],
    };
  }
}
