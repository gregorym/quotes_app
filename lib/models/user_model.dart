import 'package:timezone/timezone.dart' as tz;

class User {
  final String id;
  final String? email;
  final String? name;
  final String? gender;
  final tz.TZDateTime? lastOpened;
  final tz.TZDateTime? createdAt;

  User({
    required this.id,
    this.email,
    this.name,
    this.gender,
    this.lastOpened,
    this.createdAt
  });

  factory User.fromJson(Map<dynamic, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      gender: json['gender'],
      lastOpened: tz.TZDateTime.parse(tz.local, json['lastOpened']),
      createdAt: tz.TZDateTime.parse(tz.local, json['createdAt']),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'gender': gender,
      'lastOpened': lastOpened.toString(),
      'createdAt': createdAt.toString(),
    };
  }
}
