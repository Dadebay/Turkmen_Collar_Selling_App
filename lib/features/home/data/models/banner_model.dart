import '../../../../core/utils/safe_parser.dart';
import '../../domain/entities/banner_entity.dart';

class BannerModel {
  const BannerModel({this.id, this.image, this.title, this.description});

  final int? id;
  final String? image;
  final String? title;
  final String? description;

  factory BannerModel.fromJson(Map<dynamic, dynamic> json) => BannerModel(
    id: SafeParser.asIntOrNull(json['id']),
    image: SafeParser.asStringOrNull(json['image']),
    title: SafeParser.asStringOrNull(json['title']),
    description: SafeParser.asStringOrNull(json['description']),
  );

  BannerEntity toEntity() => BannerEntity(
    id: id,
    image: image,
    title: title,
    description: description,
  );
}
