import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/tool_activity.dart';
import 'auth_provider.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKeyPrefix = 'tool_history_';
  static const int _maxEntries = 100;

  final FlutterSecureStorage _storage;

  AuthProvider? _authProvider;
  VoidCallback? _authListener;
  bool _listeningToAuth = false;
  String? _currentUid;
  bool _hasLoadedForCurrentUser = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final List<ToolActivity> _activities = <ToolActivity>[];
  List<ToolActivity> get activities => List.unmodifiable(_activities);

  void update(AuthProvider authProvider) {
    final authChanged = !identical(_authProvider, authProvider);

    if (_listeningToAuth && authChanged && _authProvider != null && _authListener != null) {
      _authProvider!.removeListener(_authListener!);
      _listeningToAuth = false;
    }

    _authProvider = authProvider;
    _authListener ??= _handleAuthChanged;

    if (!_listeningToAuth && _authListener != null) {
      _authProvider!.addListener(_authListener!);
      _listeningToAuth = true;
    }

    _handleAuthChanged();
  }

  Future<void> fetchHistory() async {
    final authProvider = _authProvider;
    if (authProvider == null) {
      _resetState();
      return;
    }

    final uid = authProvider.user?.uid;
    if (uid == null) {
      _currentUid = null;
      _resetState();
      return;
    }

    _currentUid = uid;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _readActivities(uid);
      _activities
        ..clear()
        ..addAll(items);
      _hasLoadedForCurrentUser = true;
    } catch (e) {
      _error = e.toString();
      _activities.clear();
      _hasLoadedForCurrentUser = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordActivity({
    required String toolId,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> outputs,
  }) async {
    final uid = _authProvider?.user?.uid;
    if (uid == null) {
      return;
    }

    if (_currentUid != uid || !_hasLoadedForCurrentUser) {
      try {
        final existing = await _readActivities(uid);
        _activities
          ..clear()
          ..addAll(existing);
      } catch (e) {
        _error = e.toString();
        _activities.clear();
      }
      _currentUid = uid;
      _hasLoadedForCurrentUser = true;
    }

    final now = DateTime.now().toUtc();
    final activity = ToolActivity(
      id: now.microsecondsSinceEpoch.toString(),
      toolId: toolId,
      inputs: inputs,
      outputs: outputs,
      timestamp: now,
    );

    _activities
      ..insert(0, activity);

    if (_activities.length > _maxEntries) {
      _activities.removeRange(_maxEntries, _activities.length);
    }

    try {
      await _storage.write(
        key: _storageKeyFor(uid),
        value: jsonEncode(_activities.map((a) => a.toJson()).toList()),
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<List<ToolActivity>> _readActivities(String uid) async {
    final raw = await _storage.read(key: _storageKeyFor(uid));
    if (raw == null || raw.isEmpty) {
      return <ToolActivity>[];
    }

    final decoded = jsonDecode(raw);
    final items = <ToolActivity>[];

    if (decoded is List) {
      for (final entry in decoded) {
        Map<String, dynamic>? map;
        if (entry is Map<String, dynamic>) {
          map = entry;
        } else if (entry is Map) {
          map = entry.map((key, value) => MapEntry('$key', value));
        }

        if (map == null) {
          continue;
        }

        final activity = ToolActivity.fromJson(map);
        if (activity != null) {
          items.add(activity);
        }
      }
    }

    items.sort((a, b) {
      final aTs = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTs = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTs.compareTo(aTs);
    });

    return items;
  }

  void _handleAuthChanged() {
    final uid = _authProvider?.user?.uid;
    if (uid == null) {
      _currentUid = null;
      _resetState();
      return;
    }

    if (_currentUid == uid && _hasLoadedForCurrentUser) {
      return;
    }

    _currentUid = uid;
    _hasLoadedForCurrentUser = false;
    fetchHistory();
  }

  void _resetState() {
    _activities.clear();
    _isLoading = false;
    _error = null;
    _hasLoadedForCurrentUser = false;
    notifyListeners();
  }

  String _storageKeyFor(String uid) => '$_storageKeyPrefix$uid';

  @override
  void dispose() {
    if (_authListener != null && _authProvider != null && _listeningToAuth) {
      _authProvider!.removeListener(_authListener!);
    }
    _authListener = null;
    _listeningToAuth = false;
    _authProvider = null;
    super.dispose();
  }
}
