import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'theme_mode';

  final FlutterSecureStorage _storage;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> toggleTheme() async {
    final nextMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(nextMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    try {
      await _storage.write(key: _prefKey, value: mode.name);
    } catch (_) {
      // Ignore storage errors; the in-memory theme will still update the UI.
    }
  }

  Future<void> _loadThemeMode() async {
    try {
      final stored = await _storage.read(key: _prefKey);
      if (stored == null) {
        return;
      }

      final parsed = ThemeMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => ThemeMode.light,
      );

      if (parsed != _themeMode) {
        _themeMode = parsed;
        notifyListeners();
      }
    } catch (_) {
      // If reading fails we stick with the default light theme.
    }
  }
}
