/// Canonical representation of the current user (`GET /api/v1/users/me`).
///
/// This single model backs every consumer of that endpoint: auth token
/// validation, the wallet balance, and the profile screen.
class UserMeModel {
  const UserMeModel({
    this.id,
    this.phone,
    this.name,
    this.surname,
    this.balance,
  });

  final int? id;
  final String? phone;
  final String? name;
  final String? surname;

  /// Raw balance in cents, as returned by the API.
  final int? balance;

  /// Balance in currency units (the API stores cents).
  double get balanceAmount => (balance ?? 0) / 100;

  factory UserMeModel.fromJson(Map<String, dynamic> json) {
    // The endpoint sometimes wraps the user under a `data` envelope.
    final map = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return UserMeModel(
      id: map['id'] is int ? map['id'] as int : 0,
      phone: map['phone']?.toString(),
      name: map['name']?.toString(),
      surname: map['surname']?.toString(),
      balance: map['balance'] is int ? map['balance'] as int : 0,
    );
  }
}
