class AboutUsModel {
  final String? title;
  final String? body;

  AboutUsModel({this.title, this.body});

  factory AboutUsModel.fromJson(Map<String, dynamic> json) {
    return AboutUsModel(
      title: json['title']?.toString(),
      body: json['body']?.toString(),
    );
  }
}

class FAQModel {
  final String? title;
  final String? body;
  final List<String> images;

  FAQModel({this.title, this.body, this.images = const []});

  factory FAQModel.fromJson(Map<dynamic, dynamic> json) {
    return FAQModel(
      title: json['title']?.toString(),
      body: json['body']?.toString(),
      images:
          (json['images'] as List?)
              ?.map((e) => e?.toString())
              .whereType<String>()
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}

class ConfigModel {
  final String? contactPhone;

  ConfigModel({this.contactPhone});

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(contactPhone: json['contact_phone']?.toString());
  }
}

class FilterElementModel {
  final int? id;
  final String? name;
  final String? image;

  FilterElementModel({this.id, this.name, this.image});

  factory FilterElementModel.fromJson(Map<dynamic, dynamic> json) {
    return FilterElementModel(
      id: json['id'] is int ? json['id'] as int : 0,
      name: json['name']?.toString(),
      image: json['image']?.toString(),
    );
  }
}
