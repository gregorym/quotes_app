import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  final _storage = const FlutterSecureStorage();

  Future getSession() async {
    final session = await _storage.read(key: 'session');

    if (session != null) {
      return jsonDecode(session);
    }

    return null;
  }

  Future<void> setSession(param0) async {
    await _storage.write(key: 'session', value: "{}");
  }

  Future<void> deleteSession() async {
    await _storage.delete(key: 'session');
  }
}
