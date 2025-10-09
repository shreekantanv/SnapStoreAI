import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  static const _completedKey = 'onboarding_completed';
  static const _completedVersionKey = 'onboarding_completed_version';
  static SharedPreferences? _prefs;
  static bool _ephemeralCompleted = false;
  static String? _cachedVersion;

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

  static Future<String?> _getCurrentVersion() async {
    if (_cachedVersion != null) {
      return _cachedVersion;
    }
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = packageInfo.buildNumber;
      final version = buildNumber.isEmpty
          ? packageInfo.version
          : '${packageInfo.version}+$buildNumber';
      _cachedVersion = version;
      return version;
    } catch (err, stack) {
      debugPrint('Failed to read package version for onboarding: $err');
      debugPrint('$stack');
      return null;
    }
  }

  static Future<bool> isCompleted() async {
    if (_ephemeralCompleted) {
      return true;
    }
    final currentVersion = await _getCurrentVersion();
    final prefs = await _getPrefs();
    if (prefs == null) {
      return false;
    }
    if (currentVersion == null) {
      final completed = prefs.getBool(_completedKey) ?? false;
      if (completed) {
        _ephemeralCompleted = true;
      }
      return completed;
    }

    final storedVersion = prefs.getString(_completedVersionKey);
    final legacyCompleted = prefs.getBool(_completedKey) ?? false;
    final hasCompletedCurrentVersion =
        storedVersion == currentVersion || (storedVersion == null && legacyCompleted);

    if (hasCompletedCurrentVersion) {
      _ephemeralCompleted = true;
      if (storedVersion == null) {
        try {
          await prefs.setString(_completedVersionKey, currentVersion);
        } catch (err, stack) {
          debugPrint('Failed to migrate onboarding completion version: $err');
          debugPrint('$stack');
        }
      }
    }
    return hasCompletedCurrentVersion;
  }

  static Future<void> markCompleted() async {
    _ephemeralCompleted = true;
    final currentVersion = await _getCurrentVersion();
    final prefs = await _getPrefs();
    if (prefs == null) {
      return;
    }
    try {
      await prefs.setBool(_completedKey, true);
      if (currentVersion != null) {
        await prefs.setString(_completedVersionKey, currentVersion);
      }
    } catch (err, stack) {
      debugPrint('Failed to persist onboarding completion: $err');
      debugPrint('$stack');
    }
  }
}
