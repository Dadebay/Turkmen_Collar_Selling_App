import 'download_file_model.dart';

class DownloadedProductModel {
  final int? id;
  final String? name;
  final String? description;
  final int? price;
  final String? machineName;
  final String? createdAt;
  final int? views;
  final int? downloads;
  final List<dynamic>? images;
  final List<DownloadFileModel>? files;

  DownloadedProductModel({
    this.id,
    this.name,
    this.description,
    this.price,
    this.machineName,
    this.createdAt,
    this.views,
    this.downloads,
    this.images,
    this.files,
  });

  factory DownloadedProductModel.fromJson(Map<dynamic, dynamic> json) {
    final rawImages = json['images'];
    final List<dynamic> images = rawImages is List ? List.from(rawImages) : [];
    final rawFiles = json['files'];
    final List<DownloadFileModel> files = rawFiles is List
        ? rawFiles
              .whereType<Map>()
              .map(
                (e) => DownloadFileModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <DownloadFileModel>[];

    return DownloadedProductModel(
      id: json['id'] is int ? json['id'] as int : 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price'] is int ? json['price'] as int : 0,
      machineName: json['machine_name']?.toString() ?? '',
      views: json['views'] is int ? json['views'] as int : 0,
      createdAt: json['created_at']?.toString(),
      downloads: json['downloads'] is int ? json['downloads'] as int : 0,
      files: files,
      images: images,
    );
  }
}
