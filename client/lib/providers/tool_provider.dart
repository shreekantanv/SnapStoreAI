// lib/providers/tool_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tool.dart';

class ToolProvider {
  final FirebaseFirestore _firestore;
  late final Stream<List<Tool>> _toolsStream;

  ToolProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _toolsStream = _firestore.collection('tools').snapshots().map((snap) {
      return snap.docs.map((d) => Tool.fromJson(d.data(), d.id)).toList();
    });
  }

  Stream<List<Tool>> get tools => _toolsStream;

  Stream<List<Tool>> getToolsByIds(List<String> ids) {
    if (ids.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('tools')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => Tool.fromJson(d.data(), d.id)).toList();
    });
  }
}
