import 'dart:collection';

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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'toolId': toolId,
      'inputs': Map<String, dynamic>.from(inputs),
      'outputs': Map<String, dynamic>.from(outputs),
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  static ToolActivity? fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim();
    final toolId = (json['toolId'] as String?)?.trim();
    if (id == null || id.isEmpty || toolId == null || toolId.isEmpty) {
      return null;
    }

    return ToolActivity(
      id: id,
      toolId: toolId,
      inputs: _coerceMap(json['inputs']),
      outputs: _coerceMap(json['outputs']),
      timestamp: _parseTimestamp(json['timestamp']),
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
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
