import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    var box = await Hive.openBox(_boxName);
    if (!box.containsKey(_boxName)) {
      User u = User(
          id: uuid.v4(), lastOpened: tz.TZDateTime.now(tz.local), createdAt: tz.TZDateTime.now(tz.local));
      await box.put(_boxName, u.toJson());
    }

    var data = box.get(_boxName) as Map<dynamic, dynamic>?;
    data!['lastOpened'] = tz.TZDateTime.now(tz.local).toString();
    User u = User.fromJson(data);

    await box.put(_boxName, u.toJson());
    setUser(u);
    return u;
  }

  Future<void> updateUserName(String name) async {
    var box = await Hive.openBox(_boxName);
    if (box.containsKey(_boxName)) {
      var data = box.get(_boxName) as Map<dynamic, dynamic>;
      data['name'] = name;
      User updatedUser = User.fromJson(data);
      await box.put(_boxName, updatedUser.toJson());
      setUser(updatedUser);
    } else {
      print('No existing user data found!');
    }
  }
}
