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
    User? user;

    try {
      final raw = box.get(_boxName);
      if (raw is Map) {
        final stored = User.fromJson(Map<dynamic, dynamic>.from(raw));
        if (stored.id.isNotEmpty) user = stored;
      }
    } catch (_) {
      await box.delete(_boxName);
    }

    if (user == null) {
      final now = tz.TZDateTime.now(tz.local);
      user = User(id: uuid.v4(), lastOpened: now, createdAt: now);
    }

    final updated = User(
      id: user.id,
      email: user.email,
      name: user.name,
      gender: user.gender,
      lastOpened: tz.TZDateTime.now(tz.local),
      createdAt: user.createdAt ?? tz.TZDateTime.now(tz.local),
    );
    await box.put(_boxName, updated.toJson());
    setUser(updated);
    return updated;
  }

  Future<void> updateUserName(String name) async {
    final box = await Hive.openBox(_boxName);
    if (!box.containsKey(_boxName)) return;

    final data = Map<dynamic, dynamic>.from(
      box.get(_boxName) as Map<dynamic, dynamic>,
    );
    data['name'] = name;
    final updatedUser = User.fromJson(data);
    await box.put(_boxName, updatedUser.toJson());
    setUser(updatedUser);
  }
}
