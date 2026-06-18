import 'dart:convert';

class LocalUser {
  final String name;
  final String email;

  const LocalUser({
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
    };
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory LocalUser.fromJson(String source) {
    return LocalUser.fromMap(json.decode(source) as Map<String, dynamic>);
  }
}
