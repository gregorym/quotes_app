import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';

const uuid = Uuid();

final userProvider = FutureProvider<User>((ref) async {
  final controller = UserController();
  return await controller.fetchUser();
});

class UserController extends StateNotifier<User?> {
  UserController() : super(null);
  final String _boxName = 'userBox';

  void setUser(User? user) => state = user;

  // fetch user
  Future<User> fetchUser() async {
    final box = await Hive.openBox(_boxName);
    if (!box.containsKey(_boxName)) {
      final now = tz.TZDateTime.now(tz.local);
      final user = User(id: uuid.v4(), lastOpened: now, createdAt: now);
      await box.put(_boxName, user.toJson());
    }

    final data = box.get(_boxName) as Map<dynamic, dynamic>?;
    data!['lastOpened'] = tz.TZDateTime.now(tz.local).toString();
    final user = User.fromJson(data);

    await box.put(_boxName, user.toJson());
    setUser(user);
    return user;
  }

  Future<void> updateUserName(String name) async {
    final box = await Hive.openBox(_boxName);
    if (!box.containsKey(_boxName)) return;

    final data = box.get(_boxName) as Map<dynamic, dynamic>;
    data['name'] = name;
    final updatedUser = User.fromJson(data);
    await box.put(_boxName, updatedUser.toJson());
    setUser(updatedUser);
  }
}
