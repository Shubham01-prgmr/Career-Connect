
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save the current user's profile.
  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Save a job application for the currently signed-in user.
  static Future<void> saveJobApplication({
    required String jobId,
    required String jobTitle,
    required String company,
    required String sector,
    required String qualification,
    required String experience,
    required String skills,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in before applying for a job.');
    }

    if (jobId.trim().isEmpty) {
      throw Exception('Job ID is empty. Cannot submit application.');
    }

    final applicationId = '${user.uid}_$jobId';
    final applicationRef =
        _db.collection('applications').doc(applicationId);

    // The transaction checks and creates the document atomically.
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(applicationRef);

      if (existing.exists) {
        throw Exception('You have already applied for this job.');
      }

      transaction.set(applicationRef, {
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'jobId': jobId,
        'jobTitle': jobTitle,
        'company': company,
        'sector': sector,
        'qualification': qualification,
        'experience': experience,
        'skills': skills,
        'status': 'Pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Check whether the current user has applied for a job.
  static Future<bool> hasApplied(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final document = await _db
        .collection('applications')
        .doc('${user.uid}_$jobId')
        .get();

    return document.exists;
  }

  // Retrieve all applications belonging to the current user.
  static Future<List<Map<String, dynamic>>> getMyApplications() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return [];
    }

    final snapshot = await _db
        .collection('applications')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  // Listen for application changes in real time.
  static Stream<List<Map<String, dynamic>>> watchMyApplications() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _db
        .collection('applications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // Retrieve the current user's profile.
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final snapshot =
        await _db.collection('users').doc(user.uid).get();

    return snapshot.data();
  }
}
