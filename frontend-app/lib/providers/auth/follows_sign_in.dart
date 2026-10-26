import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_provider.dart';

/// For providers that hold the signed-in customer's own data (profile, cart, wishlist, orders,
/// notifications). main.dart calls [syncWith] whenever the sign-in state changes.
///
/// Data is loaded lazily: a screen calls [ensureLoaded] when it needs the data, so signing in doesn't
/// fetch everything at once. Only providers with [loadsOnSignIn] (the profile) load right away.
/// For guests and after signing out, the data is cleared from memory (nothing saved is deleted).
mixin FollowsSignIn on ChangeNotifier {
  bool _signedIn = false;
  bool _requested = false;

  /// True while a customer is signed in.
  bool get signedIn => _signedIn;

  /// True once the data has been requested for this sign-in (it may still be on its way).
  bool get isLoaded => _requested;

  /// Load as soon as someone signs in instead of waiting for a screen to ask.
  bool get loadsOnSignIn => false;

  /// Loads the signed-in customer's data.
  Future<void> load();

  /// Empties the data held in memory (without deleting anything saved).
  void unload();

  /// Records that the data is now known (e.g. a cart change returned the whole cart).
  void markLoaded() => _requested = _signedIn;

  /// Loads the data the first time a screen needs it (later calls do nothing; use [load] to refresh).
  Future<void> ensureLoaded() async {
    if (!_signedIn || _requested) return;
    _requested = true;
    await load();
  }

  void syncWith(AuthStatus status) {
    final signedIn = status == AuthStatus.signedIn;
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    _requested = false;
    // Runs after the current build, because providers can't notify while widgets are building.
    scheduleMicrotask(() {
      if (!_signedIn) {
        unload();
      } else if (loadsOnSignIn) {
        ensureLoaded();
      }
    });
  }
}
