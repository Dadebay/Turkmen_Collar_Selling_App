class AboutUsModel {
  final String? title;
  final String? body;
  AboutUsModel({
    this.title,
    this.body,
  });

  factory AboutUsModel.fromJson(Map<String, dynamic> json) {
    return AboutUsModel(
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

class FAQModel {
  final String? title;
  final String? body;
  FAQModel({
    this.title,
    this.body,
  });

  factory FAQModel.fromJson(Map<dynamic, dynamic> json) {
    return FAQModel(
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

class UserMeModel {
  final int? id;
  final String? phone;
  final String? name;
  final String? surname;
  final int? balance;
  UserMeModel({
    this.id,
    this.phone,
    this.name,
    this.surname,
    this.balance,
  });

  factory UserMeModel.fromJson(Map<String, dynamic> json) {
    return UserMeModel(
      id: json['id'] as int,
      phone: json['phone'] ?? '62990344',
      name: json['name'] ?? 'Aman',
      surname: json['surname'] ?? 'Amanow',
      balance: json['balance'] ?? 0,
    );
  }
}

class GetFilterElements {
  final int? id;
  final String? name;
  final String? image;
  GetFilterElements({
    this.id,
    this.name,
    this.image,
  });

  factory GetFilterElements.fromJson(Map<dynamic, dynamic> json) {
    return GetFilterElements(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
    );
  }
}
