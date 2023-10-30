import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {

  Future signIn(String email, String password) async {
    try {
      

      return null;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future signUp(String email, String password) async {
    try {
      return null;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<bool> isLoggedIn(String sessionString) async {
    try {

      return true;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
