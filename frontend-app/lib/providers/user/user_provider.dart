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

  /// Saves the profile. Returns false when saving failed (the screen keeps the form open).
  Future<bool> update({required String name, required String email, required String phone}) async {
    if (user == null || isSaving) return false;
    isSaving = true;
    notifyListeners();
    try {
      final updated = user!.copyWith(name: name.trim(), email: email.trim().toLowerCase(), phone: phone.trim());
      await Future.delayed(const Duration(milliseconds: 400));
      await _service.saveUser(updated);
      user = updated;
      return true;
    } catch (_) {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
