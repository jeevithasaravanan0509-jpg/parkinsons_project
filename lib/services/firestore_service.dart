import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> createUserProfile({
    required String fullName,
    required String email,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await _firestore.collection('users').doc(user.uid).set(
      {
        'uid': user.uid,
        'fullName': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    return _firestore.collection('users').doc(user.uid).get();
  }

  Future<void> updateUserProfile({
    String? fullName,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final Map<String, dynamic> data = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fullName != null) {
      data['fullName'] = fullName;
    }

    if (phoneNumber != null) {
      data['phoneNumber'] = phoneNumber;
    }

    if (dateOfBirth != null) {
      data['dateOfBirth'] = dateOfBirth;
    }

    if (gender != null) {
      data['gender'] = gender;
    }

    await _firestore.collection('users').doc(user.uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<void> saveSymptomRecord({
    required Map<String, dynamic> symptoms,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('symptoms')
        .add({
      ...symptoms,
      'recordedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> symptomRecords() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('symptoms')
        .orderBy('recordedAt', descending: true)
        .snapshots();
  }
}