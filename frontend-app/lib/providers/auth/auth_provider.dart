import 'package:flutter/foundation.dart';

import '../../services/api/api_client.dart';
import '../../services/api/api_exception.dart';
import '../../services/auth/auth_service.dart';

/// What happened when changing the password.
enum PasswordChangeResult { changed, wrongPassword, failed }

/// Where the user is in the sign-in flow.
enum AuthStatus { unknown, signedOut, guest, signedIn }

/// Sign-in state. The router listens to this to send guests to the login screen.
class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthStatus status = AuthStatus.unknown;
  bool isLoading = false;
  bool isChangingPassword = false;
  String? passwordError; // user-facing reason the last password change failed

  /// True after the server ended the session (tokens could not be refreshed); Sign in explains it.
  bool sessionExpired = false;

  AuthProvider() {
    ApiClient.instance.onSessionExpired = _onSessionExpired;
  }

  bool get isSignedIn => status == AuthStatus.signedIn;

  /// Reads the saved session (called by the splash screen).
  Future<void> init() async {
    final session = await _service.getSession();
    status = switch (session) {
      SessionType.signedIn => AuthStatus.signedIn,
      SessionType.guest => AuthStatus.guest,
      null => AuthStatus.signedOut,
    };
    notifyListeners();
  }

  /// Returns an error message, or null when sign-in worked.
  Future<String?> login(String email, String password) {
    return _run(() => _service.login(email, password));
  }

  /// Returns an error message, or null when the account was created (and signed in).
  Future<String?> register({required String name, required String email, required String phone, required String password}) {
    return _run(() => _service.register(name: name, email: email, phone: phone, password: password));
  }

  Future<void> continueAsGuest() async {
    await _service.continueAsGuest();
    status = AuthStatus.guest;
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.logout();
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<PasswordChangeResult> changePassword({required String currentPassword, required String newPassword}) async {
    if (isChangingPassword) return PasswordChangeResult.failed;
    isChangingPassword = true;
    passwordError = null;
    notifyListeners();
    try {
      await _service.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      return PasswordChangeResult.changed;
    } on ApiException catch (e) {
      passwordError = e.userMessage;
      return e.code == 'CURRENT_PASSWORD_INCORRECT' ? PasswordChangeResult.wrongPassword : PasswordChangeResult.failed;
    } finally {
      isChangingPassword = false;
      notifyListeners();
    }
  }

  void _onSessionExpired() {
    if (!isSignedIn) return;
    status = AuthStatus.signedOut;
    sessionExpired = true;
    notifyListeners();
  }

  Future<String?> _run(Future<void> Function() action) async {
    isLoading = true;
    notifyListeners();
    try {
      await action();
      status = AuthStatus.signedIn;
      sessionExpired = false;
      return null;
    } on ApiException catch (e) {
      return e.userMessage;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
