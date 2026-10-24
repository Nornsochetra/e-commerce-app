import 'package:flutter/foundation.dart';

import '../../services/auth/auth_service.dart';

/// Where the user is in the sign-in flow.
enum AuthStatus { unknown, signedOut, guest, signedIn }

/// Sign-in state. The router listens to this to send guests to the login screen.
class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  AuthStatus status = AuthStatus.unknown;
  bool isLoading = false;

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
  Future<String?> login(String email, String password) async {
    return _run(() => _service.login(email, password), onSuccess: AuthStatus.signedIn);
  }

  /// Returns an error message, or null when the account was created (and signed in).
  Future<String?> register({required String name, required String email, required String phone, required String password}) async {
    return _run(() => _service.register(name: name, email: email, phone: phone, password: password), onSuccess: AuthStatus.signedIn);
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

  Future<void> requestPasswordReset(String email) => _service.requestPasswordReset(email);

  Future<String?> _run(Future<void> Function() action, {required AuthStatus onSuccess}) async {
    isLoading = true;
    notifyListeners();
    try {
      await action();
      status = onSuccess;
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
