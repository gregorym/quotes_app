import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

class UserRepository {
  Future<void> createUser(User user) async {
    try {} catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  // fetch user
  Future fetchUser(String userId) async {
    try {
      User u = User(id: "1", name: "Greg", email: "");
      return u;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});
