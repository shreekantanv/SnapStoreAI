// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn(scopes: ['email']);

  User? user;
  bool isLoading = true;
  String? error;

  AuthProvider() {
    _auth.authStateChanges().listen((u) {
      user = u;
      isLoading = false;
      error = null;                // ← clear stale errors once we have a user
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    _start();
    try {
      final acct = await _google.signIn();
      if (acct == null) return _stop(); // user cancelled
      final auth = await acct.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await _auth.signInWithCredential(cred); // listener will fire
      _stop();
    } catch (e) {
      error = e.toString();
      _stop();
    }
  }

  Future<void> signInAnonymously() async {
    _start();
    try {
      await _auth.signInAnonymously();       // success -> listener fires
      _stop();
    } catch (e) {
      error = e.toString();
      _stop();
    }
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    await _auth.signOut();
    // Also sign out of Google to clear session, if previously signed in
    try {
      await _google.signOut();
    } catch (e) {
      debugPrint("Error signing out from Google: $e");
      // Ignore error, as user might not have been signed in with Google.
    }
  }

  void _start() { isLoading = true; error = null; notifyListeners(); }
  void _stop()  { isLoading = false; notifyListeners(); }
}
