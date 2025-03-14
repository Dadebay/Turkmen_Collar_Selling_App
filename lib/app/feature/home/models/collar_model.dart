// ignore_for_file: unnecessary_null_comparison

class FavoritesModelCollar {
  final int? id;
  final String? name;
  final int? price;
  final String? createdAt;
  final String? image;
  FavoritesModelCollar({
    this.name,
    this.price,
    this.image,
    this.id,
    this.createdAt,
  });

  factory FavoritesModelCollar.fromJson(Map<dynamic, dynamic> json) {
    return FavoritesModelCollar(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now(),
      price: json['price'] ?? 0,
      image: json['images'][0] ?? '',
    );
  }
}

class CollarByIDModel {
  final String? createdAt;
  final String? desc;
  final int? downloads;
  final List<FilesModel>? files;
  final int? id;
  final List? images;
  final String? machineName;
  final String? name;
  final int? price;
  final String? tag;
  final int? views;
  CollarByIDModel({
    this.id,
    this.name,
    this.desc,
    this.price,
    this.views,
    this.downloads,
    this.tag,
    this.machineName,
    this.createdAt,
    this.images,
    this.files,
  });

  factory CollarByIDModel.fromJson(Map<dynamic, dynamic> json) {
    final List image = json['images'] as List;
    List<dynamic> images = [];
    if (image == null) {
      images = [''];
    } else {
      images = image.map((value) => value).toList();
    }
    return CollarByIDModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      desc: json['description'] ?? '',
      views: json['views'] ?? 0,
      downloads: json['downlaods'] ?? 0,
      price: json['price'] ?? 0,
      tag: json['tag'] ?? '',
      machineName: json['machine_name'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now(),
      images: images,
      files: (json['files'] as List).map((json) => FilesModel.fromJson(json)).toList(),
    );
  }
}

class FilesModel {
  String? createtdAt;
  int? id;
  List? images;
  String? machineLogo;
  String? machineName;
  int? price;
  bool? purchased;
  FilesModel({this.id, this.price, this.machineLogo, this.createtdAt, this.images, this.purchased, this.machineName});

  factory FilesModel.fromJson(Map<String, dynamic> json) {
    final List image = json['images'] as List;
    List<dynamic> images = [];
    if (image == null) {
      images = [''];
    } else {
      images = image.map((value) => value).toList();
    }
    return FilesModel(
      id: json['id'] ?? 0,
      price: json['price'] ?? 0,
      machineLogo: json['machine_thumb'] ?? '',
      machineName: json['machine_name'] ?? 'Ady',
      createtdAt: json['created_at'],
      images: images,
      purchased: json['purchased'] ?? false,
    );
  }
}
