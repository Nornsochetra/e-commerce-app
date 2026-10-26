import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_provider.dart';

/// For providers that hold the signed-in customer's own data (profile, cart, wishlist, orders,
/// notifications). main.dart calls [syncWith] whenever the sign-in state changes, so the data is
/// loaded after signing in and cleared from memory for guests and after signing out.
/// (Clearing only empties what is shown; nothing saved is deleted.)
mixin FollowsSignIn on ChangeNotifier {
  bool _signedIn = false;

  /// True while a customer is signed in.
  bool get signedIn => _signedIn;

  /// Loads the signed-in customer's data.
  Future<void> load();

  /// Empties the data held in memory (without deleting anything saved).
  void unload();

  void syncWith(AuthStatus status) {
    final signedIn = status == AuthStatus.signedIn;
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    // Runs after the current build, because providers can't notify while widgets are building.
    scheduleMicrotask(() {
      if (_signedIn) {
        load();
      } else {
        unload();
      }
    });
  }
}
