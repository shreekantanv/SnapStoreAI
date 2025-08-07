// lib/providers/tool_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/tool.dart';

class ToolProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  bool isLoading = false;
  String? error;
  final List<Tool> _allTools = [];

  ToolProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _loadTools();
  }

  /// Expose all tools for filtering / searching:
  List<Tool> get allTools => List.unmodifiable(_allTools);

  Map<String, List<Tool>> get groupedByCategory {
    final map = <String, List<Tool>>{};
    for (var t in _allTools) {
      map.putIfAbsent(t.category, () => []).add(t);
    }
    return map;
  }

  Future<void> _loadTools() async {
    isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore.collection('tools').get();
      _allTools
        ..clear()
        ..addAll(snap.docs.map((d) => Tool.fromJson(d.data(), d.id)));
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => _loadTools();
}
