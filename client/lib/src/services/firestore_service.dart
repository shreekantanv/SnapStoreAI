import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_tool_store_client/src/models/user_profile.dart';
import 'package:ai_tool_store_client/src/models/ledger_entry.dart';

/// Provider for the FirestoreService.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

/// A service class to interact with Firestore.
///
/// This service handles all read operations from the client. All write
/// operations are handled by the backend Cloud Functions for security.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService(this._db);

  /// Returns a stream of the user's profile document.
  ///
  /// This allows the UI to reactively update when the user's credit balance
  /// or other profile information changes.
  Stream<UserProfile> userProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      // Return a default/initial state if the document doesn't exist yet.
      return UserProfile.initial(uid);
    });
  }

  /// Fetches the user's ledger history (their transaction records).
  ///
  /// This returns a Future, as it's typically a one-time read when the
  /// user visits their wallet or history screen.
  Future<List<LedgerEntry>> getLedgerHistory(String uid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('ledger')
          .orderBy('ts', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => LedgerEntry.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching ledger history: $e');
      return [];
    }
  }
}
