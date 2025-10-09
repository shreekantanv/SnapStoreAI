import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/tool_activity.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'tool_history_global';
  static const int _maxEntries = 100;

  final FlutterSecureStorage _storage;

  bool _hasLoaded = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  final List<ToolActivity> _activities = <ToolActivity>[];
  List<ToolActivity> get activities => List.unmodifiable(_activities);

  Future<void> fetchHistory() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = await _readActivities();
      _activities
        ..clear()
        ..addAll(items);
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      _activities.clear();
      _hasLoaded = false;
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
    if (!_hasLoaded) {
      try {
        final existing = await _readActivities();
        _activities
          ..clear()
          ..addAll(existing);
      } catch (e) {
        _error = e.toString();
        _activities.clear();
      }
      _hasLoaded = true;
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
        key: _storageKey,
        value: jsonEncode(_activities.map((a) => a.toJson()).toList()),
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    notifyListeners();
  }

  Future<List<ToolActivity>> _readActivities() async {
    final raw = await _storage.read(key: _storageKey);
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
}
