import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/tool.dart';

class ToolProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;

  List<Tool> _tools = const [];
  Map<String, Tool> _toolById = const {};
  bool _isLoading = false;
  bool _hasLoaded = false;
  Object? _error;

  ToolProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    // Kick off the initial fetch without blocking provider creation.
    scheduleMicrotask(_loadTools);
  }

  List<Tool> get tools => List.unmodifiable(_tools);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  Object? get error => _error;

  Future<void> refresh() => _loadTools(force: true);

  Tool? toolById(String id) => _toolById[id];

  List<Tool> toolsByIds(List<String> ids) {
    if (ids.isEmpty) {
      return const [];
    }
    final result = <Tool>[];
    for (final id in ids) {
      final tool = _toolById[id];
      if (tool != null) {
        result.add(tool);
      }
    }
    return result;
  }

  Future<void> ensureLoaded() => _loadTools();

  Future<void> _loadTools({bool force = false}) async {
    if (_isLoading || (_hasLoaded && !force)) {
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('tools').get();
      final fetched = snapshot.docs
          .map((d) => Tool.fromJson(d.data(), d.id))
          .toList(growable: false);

      _tools = fetched;
      _toolById = {for (final tool in fetched) tool.id: tool};
      _error = null;
      _hasLoaded = true;
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
