import 'package:equatable/equatable.dart';

class VideoEntity extends Equatable {
  const VideoEntity({
    this.id,
    this.name,
    this.description,
    this.slug,
    this.videoUrl,
    this.pictureUrl,
    this.sortOrder,
    this.createdAt,
  });

  final int? id;
  final String? name;
  final String? description;
  final String? slug;
  final String? videoUrl;
  final String? pictureUrl;
  final int? sortOrder;
  final String? createdAt;

  @override
  List<Object?> get props => [id, slug, videoUrl];
}
