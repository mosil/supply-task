import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String contactInfo;
  final String phoneNumber;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.contactInfo,
    required this.phoneNumber,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return UserProfile(
      uid: snapshot.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      contactInfo: data['contactInfo'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'contactInfo': contactInfo,
      'phoneNumber': phoneNumber,
    };
  }
}
