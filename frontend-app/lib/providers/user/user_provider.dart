import 'package:flutter/foundation.dart';

import '../../models/user/user.dart';
import '../../services/api/api_exception.dart';
import '../../services/user/user_service.dart';
import '../auth/follows_sign_in.dart';

/// What happened when saving the profile.
enum ProfileSaveResult { saved, emailTaken, failed }

/// The signed-in customer's profile. It follows sign-in (see [FollowsSignIn]):
/// loaded from GET /auth/me after signing in, cleared after signing out.
class UserProvider extends ChangeNotifier with FollowsSignIn {
  final _service = UserService();

  User? user;
  bool isLoading = false;
  bool isSaving = false;
  String? error; // couldn't load the profile
  String? saveError; // user-facing reason the last save failed

  @override
  Future<void> load() async {
    if (!signedIn) return;
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

  @override
  void unload() {
    user = null;
    error = null;
    notifyListeners();
  }
}
