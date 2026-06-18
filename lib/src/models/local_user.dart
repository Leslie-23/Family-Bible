import 'dart:convert';

class LocalUser {
  final String? id;
  final String name;
  final String email;
  final String? token;
  final String? brandingName;

  const LocalUser({
    this.id,
    required this.name,
    required this.email,
    this.token,
    this.brandingName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'brandingName': brandingName,
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      id: map['id']?.toString(),
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      token: map['token']?.toString(),
      brandingName: map['brandingName']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory LocalUser.fromJson(String source) {
    return LocalUser.fromMap(json.decode(source) as Map<String, dynamic>);
  }
}
