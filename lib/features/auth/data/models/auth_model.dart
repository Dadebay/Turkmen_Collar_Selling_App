import '../../../../core/utils/safe_parser.dart';
import '../../domain/entities/user_entity.dart';

class AuthModel {
  const AuthModel({required this.id, required this.token, required this.phone});

  final int id;
  final String token;
  final String phone;

  factory AuthModel.fromJson(Map<String, dynamic> json, {String phone = ''}) {
    final data = SafeParser.asMapOrNull(json['data']) ?? json;
    return AuthModel(
      id: SafeParser.asInt(data['id']),
      token: SafeParser.asString(data['api_token']),
      phone: phone,
    );
  }

  UserEntity toEntity() => UserEntity(id: id, phone: phone, token: token);
}
