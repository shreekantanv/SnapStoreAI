import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

class ToolActivity {
  ToolActivity({
    required this.id,
    required this.toolId,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> outputs,
    this.timestamp,
  })  : inputs = UnmodifiableMapView(Map<String, dynamic>.from(inputs)),
        outputs = UnmodifiableMapView(Map<String, dynamic>.from(outputs));

  final String id;
  final String toolId;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final DateTime? timestamp;

  static ToolActivity? fromSnapshot(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final toolId = (data['toolId'] as String?)?.trim();
    if (toolId == null || toolId.isEmpty) {
      return null;
    }

    return ToolActivity(
      id: doc.id,
      toolId: toolId,
      inputs: _coerceMap(data['inputs']),
      outputs: _coerceMap(data['outputs']),
      timestamp: _parseTimestamp(data['ts']),
    );
  }

  static Map<String, dynamic> _coerceMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return const <String, dynamic>{};
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
