import 'package:timezone/timezone.dart' as tz;

class User {
  final String id;
  final String? email;
  final String? name;
  final String? gender;
  final tz.TZDateTime? lastOpened;
  final tz.TZDateTime? createdAt;

  User(
      {required this.id,
      this.email,
      this.name,
      this.gender,
      this.lastOpened,
      this.createdAt});

  factory User.fromJson(Map<dynamic, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      lastOpened: _parseDate(json['lastOpened']),
      createdAt: _parseDate(json['createdAt']),
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

tz.TZDateTime? _parseDate(Object? value) {
  if (value == null || value.toString() == 'null') return null;
  try {
    return tz.TZDateTime.parse(tz.local, value.toString());
  } on FormatException {
    return null;
  }
}
