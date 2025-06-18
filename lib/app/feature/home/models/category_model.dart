import 'dart:convert';

class CategoryModel {
  final int id;
  final String name;
  final bool isCollar;
  final bool isMachine;
  final String image;
  final String createdAt;
  final List<CategoryModel> children;

  CategoryModel({
    required this.id,
    required this.name,
    required this.isCollar,
    required this.isMachine,
    required this.image,
    required this.createdAt,
    required this.children,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'name',
      isCollar: json['is_collar'] ?? 'is_collar',
      isMachine: json['is_machine'] ?? 'is_machine',
      image: json['image'] ?? '',
      createdAt: json['created_at'] ?? '',
      children: (json['children'] as List?)?.map((e) => CategoryModel.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_collar': isCollar,
      'is_machine': isMachine,
      'image': image,
      'created_at': createdAt,
      'children': children.map((e) => e.toJson()).toList(),
    };
  }
}

List<CategoryModel> parseCategories(String responseBody) {
  final parsed = json.decode(responseBody)['data'] as List;
  return parsed.map((json) => CategoryModel.fromJson(json)).toList();
}
