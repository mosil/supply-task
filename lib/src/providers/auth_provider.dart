import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supply_task/src/models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfile? _user;
  bool _isNewUser = false;
  final Map<String, UserProfile?> _userCache = {};

  UserProfile? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isNewUser => _isNewUser;

  AuthProvider() {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<UserProfile?> getUserById(String userId) async {
    // Return from cache if available
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    // If the requested user is the current user, return it
    if (_user?.uid == userId) {
      _userCache[userId] = _user!;
      return _user;
    }

    // Fetch from Firestore
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final userProfile = UserProfile.fromFirestore(doc, null);
        _userCache[userId] = userProfile; // Cache the result
        return userProfile;
      }
    } catch (e) {
      debugPrint('Error fetching user by ID: $e');
    }

    _userCache[userId] = null; // Cache null if not found to prevent re-fetching
    return null;
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
    } else {
      await _fetchOrCreateUserProfile(firebaseUser);
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
      // Auth state change will be handled by the listener
    } catch (e) {
      debugPrint('Error during Google sign-in: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    _user = null;
    _userCache.clear(); // Clear cache on sign out
    notifyListeners();
  }

  Future<void> _fetchOrCreateUserProfile(firebase_auth.User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      _user = UserProfile.fromFirestore(snapshot, null);
      _isNewUser = false;
    } else {
      final newUserProfile = UserProfile(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '新使用者',
        contactInfo: '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
      );
      await docRef.set(newUserProfile.toFirestore());
      _user = newUserProfile;
      _isNewUser = true;
    }
    // Add the current user to the cache
    if (_user != null) {
      _userCache[_user!.uid] = _user!;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).update(profile.toFirestore());
    _user = profile;
    _isNewUser = false; // User is no longer new after saving profile
    _userCache[profile.uid] = profile; // Update cache
    notifyListeners();
  }
}
