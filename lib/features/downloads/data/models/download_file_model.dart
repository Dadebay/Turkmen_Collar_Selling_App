class DownloadFileModel {
  String? createdAt;
  int? id;
  List<dynamic>? images;
  String? machineLogo;
  String? machineName;
  int? price;
  bool? purchased;

  DownloadFileModel({
    this.id,
    this.price,
    this.machineLogo,
    this.createdAt,
    this.images,
    this.purchased,
    this.machineName,
  });

  factory DownloadFileModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final List<dynamic> images = rawImages is List ? List.from(rawImages) : [];
    return DownloadFileModel(
      id: json['id'] is int ? json['id'] as int : 0,
      price: json['price'] is int ? json['price'] as int : 0,
      machineLogo: json['machine_thumb']?.toString() ?? '',
      machineName: json['machine_name']?.toString() ?? 'Ady',
      createdAt: json['created_at']?.toString(),
      images: images,
      purchased: json['purchased'] is bool ? json['purchased'] as bool : false,
    );
  }
}
