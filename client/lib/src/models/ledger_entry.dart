import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single transaction in a user's ledger.
///
/// This corresponds to a document in the `/users/{uid}/ledger` subcollection.
class LedgerEntry {
  final String id;
  final String type; // 'purchase' or 'debit'
  final int amount; // positive for purchase, negative for debit
  final String? model; // e.g., 'gpt-4'
  final DateTime timestamp;

  LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    this.model,
    required this.timestamp,
  });

  /// Creates a [LedgerEntry] instance from a Firestore [DocumentSnapshot].
  factory LedgerEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LedgerEntry(
      id: doc.id,
      type: data['type'] ?? 'unknown',
      amount: data['amount'] ?? 0,
      model: data['model'],
      timestamp: (data['ts'] as Timestamp).toDate(),
    );
  }
}
