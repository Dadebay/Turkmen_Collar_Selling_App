import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.phone,
    required this.token,
  });

  final int id;
  final String phone;
  final String token;

  @override
  List<Object?> get props => [id, phone, token];
}
