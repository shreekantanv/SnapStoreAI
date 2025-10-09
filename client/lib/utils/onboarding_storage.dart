import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  static const _completedKey = 'onboarding_completed';
  static SharedPreferences? _prefs;
  static bool _ephemeralCompleted = false;

  const OnboardingStorage._();

  static Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (err, stack) {
      debugPrint('Failed to access SharedPreferences for onboarding: $err');
      debugPrint('$stack');
      return null;
    }
  }

  static Future<bool> isCompleted() async {
    if (_ephemeralCompleted) {
      return true;
    }
    final prefs = await _getPrefs();
    if (prefs == null) {
      return false;
    }
    final completed = prefs.getBool(_completedKey) ?? false;
    if (completed) {
      _ephemeralCompleted = true;
    }
    return completed;
  }

  static Future<void> markCompleted() async {
    _ephemeralCompleted = true;
    final prefs = await _getPrefs();
    if (prefs == null) {
      return;
    }
    try {
      await prefs.setBool(_completedKey, true);
    } catch (err, stack) {
      debugPrint('Failed to persist onboarding completion: $err');
      debugPrint('$stack');
    }
  }
}
