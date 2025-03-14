// ignore_for_file: unnecessary_null_comparison

import '../../home/models/collar_model.dart';

class DownloadsModel {
  final int? id;
  final String? name;
  final String? description;
  final int? price;
  final String? machineName;
  final String? createdAt;
  final int? views;
  final int? downloads;
  final List? images;
  final List<FilesModel>? files;
  DownloadsModel({
    this.name,
    this.description,
    this.price,
    this.machineName,
    this.views,
    this.downloads,
    this.images,
    this.files,
    this.id,
    this.createdAt,
  });

  factory DownloadsModel.fromJson(Map<dynamic, dynamic> json) {
    final List image = json['images'] as List;
    List<dynamic> images = [];
    if (image == null) {
      images = [''];
    } else {
      images = image.map((value) => value).toList();
    }
    return DownloadsModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'null',
      description: json['description'] ?? 'null',
      price: json['price'] ?? 'null',
      machineName: json['machine_name'] ?? 'null',
      views: json['views'] ?? 0,
      createdAt: json['created_at'],
      downloads: json['downloads'] ?? 0,
      files: (json['files'] as List).map((json) => FilesModel.fromJson(json)).toList(),
      images: images,
    );
  }
}
