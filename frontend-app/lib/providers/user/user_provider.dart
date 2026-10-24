import 'package:flutter/foundation.dart';

import '../../models/user/user.dart';
import '../../services/user/user_service.dart';

/// The signed-in customer's profile.
class UserProvider extends ChangeNotifier {
  final _service = UserService();

  User? user;
  bool isLoading = false;
  bool isSaving = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    user = await _service.getUser();
    isLoading = false;
    notifyListeners();
  }

  Future<void> update({required String name, required String email, required String phone}) async {
    if (user == null) return;
    isSaving = true;
    notifyListeners();
    final updated = user!.copyWith(name: name.trim(), email: email.trim().toLowerCase(), phone: phone.trim());
    await Future.delayed(const Duration(milliseconds: 400));
    await _service.saveUser(updated);
    user = updated;
    isSaving = false;
    notifyListeners();
  }
}
