import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    debugPrint('Checking admin for: ${user.email}');

    // Firestore Admins Collection check (by document ID)
    try {
      final doc = await _db.collection('admins').doc(user.email).get();
      debugPrint('Admin doc exists: ${doc.exists}');
      if (!doc.exists) return false;
      final data = doc.data();
      debugPrint('Admin doc data: $data');
      return data == null || data['active'] != false;
    } catch (e) {
      debugPrint('Admin check error: $e');
      return false;
    }
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
