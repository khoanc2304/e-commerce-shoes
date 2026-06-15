import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_auth;
import '../models/user_model.dart';

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final g_auth.GoogleSignIn _googleSignIn;

  AuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    g_auth.GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? g_auth.GoogleSignIn.instance;

  Stream<firebase_auth.User?> get user => _firebaseAuth.authStateChanges();

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? email,
          fullName: fullName,
          avatarUrl: '',
          role: 'user',
          shippingAddresses: [],
          createdAt: Timestamp.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        return userModel;
      } else {
        throw Exception("Sign up failed: User is null");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        return await getUserProfile(user.uid);
      } else {
        throw Exception("Sign in failed: User is null");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final g_auth.GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final g_auth.GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final firebase_auth.OAuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: null,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!);
        } else {
          // Create new user profile
          final userModel = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            fullName: user.displayName ?? 'Google User',
            avatarUrl: user.photoURL ?? '',
            role: 'user',
            shippingAddresses: [],
            createdAt: Timestamp.now(),
          );
          await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
          return userModel;
        }
      } else {
        throw Exception("Google Sign In failed: User is null");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      } else {
        throw Exception("User profile not found");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
