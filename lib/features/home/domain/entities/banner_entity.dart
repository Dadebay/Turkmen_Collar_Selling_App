import 'package:equatable/equatable.dart';

class BannerEntity extends Equatable {
  const BannerEntity({this.id, this.image, this.title, this.description});

  final int? id;
  final String? image;
  final String? title;
  final String? description;

  @override
  List<Object?> get props => [id, image];
}
