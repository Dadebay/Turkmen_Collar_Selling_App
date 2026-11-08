import '../../../../core/utils/safe_parser.dart';
import '../../domain/entities/category_entity.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.isCollar,
    required this.isMachine,
    this.children = const [],
  });

  final int id;
  final String name;
  final String image;
  final bool isCollar;
  final bool isMachine;
  final List<CategoryModel> children;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: SafeParser.asInt(json['id']),
    name: SafeParser.asString(json['name']),
    isCollar: SafeParser.asBool(json['is_collar']),
    isMachine: SafeParser.asBool(json['is_machine']),
    image: SafeParser.asString(json['image']),
    children: SafeParser.asList(
      json['children'],
      (e) => CategoryModel.fromJson(SafeParser.asMap(e)),
    ),
  );

  CategoryEntity toEntity() => CategoryEntity(
    id: id,
    name: name,
    image: image,
    isCollar: isCollar,
    isMachine: isMachine,
    children: children.map((c) => c.toEntity()).toList(),
  );
}
