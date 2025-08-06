import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's profile document in Firestore.
///
/// This class provides a type-safe way to interact with the data
/// stored in `/users/{uid}`.
class UserProfile {
  final String uid;
  final int creditsRemaining;
  final bool isPremium;
  final DateTime? premiumExpires;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.creditsRemaining,
    required this.isPremium,
    this.premiumExpires,
    required this.createdAt,
  });

  /// Creates a [UserProfile] instance from a Firestore [DocumentSnapshot].
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      creditsRemaining: data['creditsRemaining'] ?? 0,
      isPremium: data['isPremium'] ?? false,
      premiumExpires: (data['premiumExpires'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// A convenience method to create an empty or default user profile.
  factory UserProfile.initial(String uid) {
    return UserProfile(
      uid: uid,
      creditsRemaining: 0,
      isPremium: false,
      premiumExpires: null,
      createdAt: DateTime.now(),
    );
  }
}
