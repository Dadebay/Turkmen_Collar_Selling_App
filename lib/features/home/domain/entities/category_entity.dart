import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
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
  final List<CategoryEntity> children;

  @override
  List<Object?> get props => [id, name];
}
