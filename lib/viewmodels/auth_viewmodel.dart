import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_analytics_service.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthViewModel() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      _user = result.user;
      await FirebaseAnalyticsService.logLogin();
      // Save user info to Firestore on login
      if (_user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set({
          'displayName': _user!.displayName ?? '',
          'email': _user!.email ?? '',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await FirebaseAnalyticsService.logLogout();
  }

  /// Update display name in Firebase Auth + Firestore
  Future<void> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name);
      await _auth.currentUser?.reload();
      _user = _auth.currentUser;
      // Also save to Firestore users collection
      if (_user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set({'displayName': name, 'email': _user!.email}, SetOptions(merge: true));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('updateDisplayName error: $e');
      rethrow;
    }
  }

  /// Đăng nhập ẩn danh — dùng cho integration tests
  /// Yêu cầu bật Anonymous Auth trong Firebase Console
  Future<bool> signInAnonymously() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _auth.signInAnonymously();
      _user = result.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Anonymous Sign-In Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
