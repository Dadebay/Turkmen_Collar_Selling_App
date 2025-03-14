class CategoryModel {
  final int? id;
  final String? name;
  final bool? isCollar;
  final bool? isMachine;
  final List? children;
  final String? image;
  final String? createdAt;
  CategoryModel({
    this.id,
    this.createdAt,
    this.name,
    this.image,
    this.isCollar,
    this.isMachine,
    this.children,
  });

  factory CategoryModel.fromJson(Map<dynamic, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? 'Aman',
      image: json['image'] ?? 'Aman',
      createdAt: json['created_at'] ?? 'Aman',
      isCollar: json['is_collar'] ?? false,
      isMachine: json['is_machine'] ?? false,
      children: json['children'] ?? [],
    );
  }
}
