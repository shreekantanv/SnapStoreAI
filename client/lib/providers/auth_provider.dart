import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  User? user;
  bool isLoading = true;
  String? error;

  AuthProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((u) {
      user = u;
      isLoading = false;
      notifyListeners();
    });
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled
        return _setLoading(false);
      }

      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(cred);
      // authStateChanges listener will pick up the new user
    } catch (e) {
      error = e.toString();
      _setLoading(false);
    }
  }

  /// Continue as anonymous guest.
  Future<void> signInAnonymously() async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.signInAnonymously();
      // authStateChanges listener will pick up the anonymous user
    } catch (e) {
      error = e.toString();
      _setLoading(false);
    }
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    await _auth.signOut();
    // Also sign out of Google to clear session
    await _googleSignIn.signOut();
  }

  // Helpers

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  void _clearError() {
    error = null;
    notifyListeners();
  }
}
