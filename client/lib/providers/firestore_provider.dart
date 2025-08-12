import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProvider {
  final FirebaseFirestore _firestore;

  FirestoreProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<DocumentSnapshot> getUser(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Future<void> logActivity(String uid, String toolId, String prompt, String result) {
    return _firestore.collection('user_activity').add({
      'uid': uid,
      'toolId': toolId,
      'prompt': prompt,
      'result': result,
      'ts': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getActivity(String uid) {
    return _firestore
        .collection('user_activity')
        .where('uid', isEqualTo: uid)
        .orderBy('ts', descending: true)
        .snapshots();
  }
}
