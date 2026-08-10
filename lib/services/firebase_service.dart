import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> login(String email, String password) async =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<bool> register({
    required String name,
    required String studentId,
    required String email,
    required String password,
    String staffCode = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(name.trim());
    try {
      final isStaff = await _isStaffCode(staffCode);
      await _db.collection('users').doc(credential.user!.uid).set({
        'name': name.trim(),
        'studentId': studentId.trim(),
        'email': email.trim(),
        'phone': '',
        'role': isStaff ? 'staff' : 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      // Authentication succeeded, so do not report the whole registration as
      // failed when the optional Firestore profile cannot be synchronized.
      debugPrint('Unable to save the new user profile: $error');
      return false;
    }
  }

  Future<bool> _isStaffCode(String code) async {
    if (code.trim().isEmpty) return false;
    final doc = await _db.doc('settings/staffAccess').get();
    final valid = doc.data()?['code'] as String?;
    return valid != null && code.trim() == valid;
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  Future<void> logout() => _auth.signOut();

  String message(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for this email.',
        'configuration-not-found' =>
          'Firebase Authentication is not configured. Enable Email/Password sign-in in the Firebase console.',
        'operation-not-allowed' =>
          'Email/Password sign-in is disabled. Enable it in Firebase Authentication.',
        'unauthorized-domain' =>
          'This local domain is not authorized in Firebase Authentication.',
        'weak-password' =>
          'Use a stronger password with at least 8 characters.',
        'network-request-failed' =>
          'No internet connection. Check your network and try again.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        _ => '${error.message ?? 'Authentication failed.'} (${error.code})',
      };
    }
    if (error is FirebaseException) {
      return 'The Firebase backend is unavailable. Enable Cloud Firestore and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authService = AuthService();

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  User get user => FirebaseAuth.instance.currentUser!;

  Stream<DocumentSnapshot<Map<String, dynamic>>> profile() =>
      _db.collection('users').doc(user.uid).snapshots();

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
    if (data['name'] != null) {
      await user.updateDisplayName(data['name'] as String);
    }
  }

  // ---- Menu ---------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> menu() =>
      _db.collection('menu').orderBy('createdAt').snapshots();

  /// Populates the menu and staff settings on first run.
  Future<void> seedDefaults() async {
    final batch = _db.batch();
    final menuSnap = await _db.collection('menu').limit(1).get();
    if (menuSnap.docs.isEmpty) {
      for (final item in FoodItem.seed) {
        batch.set(_db.collection('menu').doc(item.id), {
          ...item.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    final staffSnap = await _db.doc('settings/staffAccess').get();
    if (!staffSnap.exists) {
      batch.set(_db.doc('settings/staffAccess'), {'code': 'CANTEEN-2026'});
    }
    if (menuSnap.docs.isEmpty || !staffSnap.exists) await batch.commit();
  }

  Future<void> setAvailability(String id, Availability value) => _db
      .collection('menu')
      .doc(id)
      .update({'availability': availabilityTo(value)});

  Future<void> addMenuItem(FoodItem item) => _db
      .collection('menu')
      .doc(item.id)
      .set({...item.toMap(), 'createdAt': FieldValue.serverTimestamp()});

  Future<void> updateMenuItem(FoodItem item) =>
      _db.collection('menu').doc(item.id).set(item.toMap(), SetOptions(merge: true));

  Future<void> deleteMenuItem(String id) =>
      _db.collection('menu').doc(id).delete();

  // ---- Orders -------------------------------------------------------------

  /// Orders live in a top-level `orders` collection so staff can see all of
  /// them; students filter by userId client-side.
  Stream<QuerySnapshot<Map<String, dynamic>>> orders() =>
      _db.collection('orders').orderBy('createdAt', descending: true).snapshots();

  Future<String> placeOrder({
    required List<Map<String, dynamic>> items,
    required int itemCount,
    required double total,
    required String pickupTime,
    required String payment,
    required String notes,
  }) async {
    final counterRef = _db.collection('counters').doc('orders');
    final orderRef = _db.collection('orders').doc();
    final number = await _db.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      final next = ((snap.data()?['count'] as num?) ?? 0) + 1;
      tx.set(counterRef, {'count': next});
      tx.set(orderRef, {
        'orderNumber': 'SC${next.toString().padLeft(4, '0')}',
        'userId': user.uid,
        'userName': user.displayName ?? '',
        'items': items,
        'itemCount': itemCount,
        'total': total,
        'pickupTime': pickupTime,
        'paymentMethod': payment,
        'notes': notes,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return next;
    });
    return 'SC${number.toString().padLeft(4, '0')}';
  }

  Future<void> setOrderStatus(String orderId, String status) =>
      _db.collection('orders').doc(orderId).update({'status': status});
}

final firestoreService = FirestoreService();
