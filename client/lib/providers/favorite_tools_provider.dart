import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FavoriteToolsProvider extends ChangeNotifier {
  FavoriteToolsProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _loadFavorites();
  }

  static const _storageKey = 'favorite_tool_ids';

  final FlutterSecureStorage _storage;
  final Set<String> _favoriteIds = <String>{};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  UnmodifiableSetView<String> get favoriteIds =>
      UnmodifiableSetView<String>(_favoriteIds);

  bool isFavorite(String toolId) => _favoriteIds.contains(toolId);

  Future<void> toggleFavorite(String toolId) async {
    final wasFavorite = _favoriteIds.contains(toolId);

    if (wasFavorite) {
      _favoriteIds.remove(toolId);
    } else {
      _favoriteIds.add(toolId);
    }
    notifyListeners();

    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(_favoriteIds.toList(growable: false)),
      );
    } catch (_) {
      // Revert in memory if persisting fails so UI stays consistent.
      if (wasFavorite) {
        _favoriteIds.add(toolId);
      } else {
        _favoriteIds.remove(toolId);
      }
      notifyListeners();
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final stored = await _storage.read(key: _storageKey);
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          _favoriteIds
            ..clear()
            ..addAll(decoded.whereType<String>());
        }
      }
    } catch (_) {
      // Ignore corrupt storage and start with an empty set.
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }
}

