import 'package:equatable/equatable.dart';

class PhotoEntity extends Equatable {
  const PhotoEntity({this.id, this.title, this.body, this.images = const []});

  final int? id;
  final String? title;
  final String? body;
  final List<String> images;

  @override
  List<Object?> get props => [id, title, images];
}
