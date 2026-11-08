import '../../../../core/utils/safe_parser.dart';
import '../../domain/entities/collar_entity.dart';

class CollarModel {
  const CollarModel({
    this.id,
    this.name,
    this.description,
    this.price,
    this.views,
    this.downloads,
    this.tag,
    this.machineName,
    this.createdAt,
    this.images = const [],
    this.files = const [],
    this.similarityScore,
  });

  final int? id;
  final String? name;
  final String? description;
  final int? price;
  final int? views;
  final int? downloads;
  final String? tag;
  final String? machineName;
  final String? createdAt;
  final List<dynamic> images;
  final List<CollarFileModel> files;
  final double? similarityScore;

  factory CollarModel.fromJson(Map<dynamic, dynamic> json) {
    return CollarModel(
      id: SafeParser.asInt(json['id']),
      name: SafeParser.asString(json['name']),
      description: SafeParser.asString(json['description']),
      views: SafeParser.asInt(json['views']),
      downloads: SafeParser.asInt(json['downloads'] ?? json['downlaods']),
      price: SafeParser.asInt(json['price']),
      tag: SafeParser.asString(json['tag']),
      machineName: SafeParser.asString(json['machine_name']),
      createdAt: SafeParser.asString(
        json['created_at'],
        fallback: DateTime.now().toString(),
      ),
      images: SafeParser.asDynamicList(json['images']),
      files: SafeParser.asList(
        json['files'],
        (e) => CollarFileModel.fromJson(SafeParser.asMap(e)),
      ),
      similarityScore: SafeParser.asDoubleOrNull(json['similarity_score']),
    );
  }

  CollarEntity toEntity() => CollarEntity(
    id: id,
    name: name,
    description: description,
    price: price,
    views: views,
    downloads: downloads,
    tag: tag,
    machineName: machineName,
    createdAt: createdAt,
    images: images,
    files: files.map((f) => f.toEntity()).toList(),
    similarityScore: similarityScore,
  );
}

class CollarFileModel {
  const CollarFileModel({
    this.id,
    this.price,
    this.machineLogo,
    this.machineName,
    this.createdAt,
    this.images = const [],
    this.purchased = false,
  });

  final int? id;
  final int? price;
  final String? machineLogo;
  final String? machineName;
  final String? createdAt;
  final List<dynamic> images;
  final bool purchased;

  factory CollarFileModel.fromJson(Map<String, dynamic> json) {
    return CollarFileModel(
      id: SafeParser.asInt(json['id']),
      price: SafeParser.asInt(json['price']),
      machineLogo: SafeParser.asString(json['machine_thumb']),
      machineName: SafeParser.asString(json['machine_name']),
      createdAt: SafeParser.asStringOrNull(json['created_at']),
      images: SafeParser.asDynamicList(json['images']),
      purchased: SafeParser.asBool(json['purchased']),
    );
  }

  CollarFileEntity toEntity() => CollarFileEntity(
    id: id,
    price: price,
    machineLogo: machineLogo,
    machineName: machineName,
    createdAt: createdAt,
    images: images,
    purchased: purchased,
  );
}
