import '../../domain/entities/video_entity.dart';

class VideoModel extends VideoEntity {
  const VideoModel({
    super.id,
    super.name,
    super.description,
    super.slug,
    super.videoUrl,
    super.pictureUrl,
    super.sortOrder,
    super.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      slug: json['slug'] as String?,
      videoUrl: json['video_url'] as String?,
      pictureUrl: json['picture_url'] as String?,
      sortOrder: json['sort_order'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }
}
