import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String username,
    required UserRole role,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'role': role == UserRole.dj ? 'dj' : 'audience',
        'date_created': FieldValue.serverTimestamp(),
      });

      // Create role-specific profile
      if (role == UserRole.dj) {
        await _firestore.collection('dj_profiles').add({
          'user_id': userCredential.user!.uid,
          'stage_name': username,
          'bio': '',
          'follower_count': 0,
          'rating': 0.0,
        });
      } else {
        await _firestore.collection('audience_profiles').add({
          'user_id': userCredential.user!.uid,
          'display_name': username,
          'joined_date': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user role
  Future<UserRole?> getUserRole(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        String role = (userDoc.data() as Map<String, dynamic>)['role'];
        return role == 'dj' ? UserRole.dj : UserRole.audience;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
