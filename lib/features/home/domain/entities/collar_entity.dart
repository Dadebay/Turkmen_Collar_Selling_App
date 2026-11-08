import 'package:equatable/equatable.dart';

class CollarEntity extends Equatable {
  const CollarEntity({
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
  final List<CollarFileEntity> files;
  final double? similarityScore;

  @override
  List<Object?> get props => [id, name];
}

class CollarFileEntity extends Equatable {
  const CollarFileEntity({
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

  @override
  List<Object?> get props => [id];
}
