import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/user/user.dart';
import '../../services/api/api_exception.dart';
import '../../services/user/user_service.dart';
import '../auth/auth_provider.dart';

/// What happened when saving the profile.
enum ProfileSaveResult { saved, emailTaken, failed }

/// The signed-in customer's profile. main.dart keeps it in step with [AuthProvider]:
/// it loads after sign-in and is cleared after sign-out (see [syncWith]).
class UserProvider extends ChangeNotifier {
  final _service = UserService();

  User? user;
  bool isLoading = false;
  bool isSaving = false;
  String? error; // couldn't load the profile
  String? saveError; // user-facing reason the last save failed
  bool _signedIn = false;

  /// Called whenever the sign-in state changes.
  void syncWith(AuthStatus status) {
    final signedIn = status == AuthStatus.signedIn;
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    // Runs after the current build, because providers can't notify while widgets are building.
    scheduleMicrotask(signedIn ? load : _clear);
  }

  Future<void> load() async {
    if (!_signedIn) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      user = await _service.getUser();
    } on ApiException catch (e) {
      error = e.userMessage;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<ProfileSaveResult> update({required String name, required String email, required String phone}) async {
    if (user == null || isSaving) return ProfileSaveResult.failed;
    isSaving = true;
    saveError = null;
    notifyListeners();
    try {
      user = await _service.updateProfile(name: name, email: email, phone: phone);
      return ProfileSaveResult.saved;
    } on ApiException catch (e) {
      saveError = e.userMessage;
      return e.code == 'EMAIL_ALREADY_REGISTERED' ? ProfileSaveResult.emailTaken : ProfileSaveResult.failed;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _clear() {
    user = null;
    error = null;
    notifyListeners();
  }
}
