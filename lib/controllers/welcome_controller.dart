import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotes_app/controllers/user_controller.dart';

import '../models/user_model.dart';


class WelcomeController extends StateNotifier<AsyncValue<User?>> {
  WelcomeController(this.userController)
      : super(const AsyncValue.data(null));

  final UserController userController;

  Future<String?> getName() async {
    final user = userController.state;
    return user?.name;
  }
}
