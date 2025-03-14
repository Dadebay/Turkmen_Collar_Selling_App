class BannerModel {
  final int? id;
  final String? image;
  final String? title;
  final String? description;
  BannerModel({
    this.id,
    this.image,
    this.title,
    this.description,
  });

  factory BannerModel.fromJson(Map<dynamic, dynamic> json) {
    return BannerModel(
      id: json['id'],
      image: json['image'],
      title: json['title'],
      description: json['description'],
    );
  }
}
