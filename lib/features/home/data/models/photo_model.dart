import '../../domain/entities/photo_entity.dart';

class PhotoModel extends PhotoEntity {
  const PhotoModel({super.id, super.title, super.body, super.images});

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as int?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      images:
          (json['images'] as List?)?.map((e) => e as String).toList() ??
          const [],
    );
  }
}
