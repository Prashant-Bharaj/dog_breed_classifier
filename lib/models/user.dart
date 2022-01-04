import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUser {
  final String? uid;
  final String? email;
  // final String? photoUrl;
  final String? name;
  // final String? bio;

  FirestoreUser({
    required this.name,
    required this.uid,
    required this.email,
    // this.photoUrl,
    // this.photoUrl,
    // this.bio
  });

  factory FirestoreUser.fromDocument(DocumentSnapshot doc) {
    return FirestoreUser(
      uid: doc['uid'],
      email: doc['email'],
      name: doc['name'],
      // photoUrl: doc['photoUrl'],
      // bio: doc['bio'],
    );
  }
}
