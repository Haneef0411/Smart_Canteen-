import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/models.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> login(String email, String password) async =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<bool> register({
    required String name,
    required String registrationNumber,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user!.updateDisplayName(name.trim());
    try {
      await _db.collection('users').doc(credential.user!.uid).set({
        'name': name.trim(),
        'registrationNumber': registrationNumber.trim(),
        // Kept temporarily so existing releases remain compatible.
        'studentId': registrationNumber.trim(),
        'email': email.trim(),
        'phone': '',
        'role': UserRole.student.firestoreValue,
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

  Stream<QuerySnapshot<Map<String, dynamic>>> users() => _db
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots();

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

  Stream<QuerySnapshot<Map<String, dynamic>>> categories() =>
      _db.collection('categories').orderBy('name').snapshots();

  Future<void> addCategory(String name) {
    final id = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return _db.collection('categories').doc(id).set({
      'name': name.trim(),
      'imageUrl': '',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setCategoryActive(String id, bool active) => _db
      .collection('categories')
      .doc(id)
      .update({'isActive': active, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> deleteCategory(String id) =>
      _db.collection('categories').doc(id).delete();

  /// Populates the starter menu on first run.
  Future<void> seedDefaults() async {
    final batch = _db.batch();
    final menuSnap = await _db.collection('menu').limit(1).get();
    final categorySnap = await _db.collection('categories').limit(1).get();
    if (menuSnap.docs.isEmpty) {
      for (final item in FoodItem.seed) {
        batch.set(_db.collection('menu').doc(item.id), {
          ...item.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    if (categorySnap.docs.isEmpty) {
      for (final category in FoodItem.categories) {
        final id = category.toLowerCase();
        batch.set(_db.collection('categories').doc(id), {
          'name': category,
          'imageUrl': '',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    if (menuSnap.docs.isEmpty || categorySnap.docs.isEmpty) {
      await batch.commit();
    }
  }

  Future<void> setAvailability(String id, Availability value) =>
      _db.collection('menu').doc(id).update({
        'availability': availabilityTo(value),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setMenuItemEnabled(String id, bool enabled) =>
      _db.collection('menu').doc(id).update({
        'isAvailable': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> addMenuItem(FoodItem item) =>
      _db.collection('menu').doc(item.id).set({
        ...item.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateMenuItem(FoodItem item) =>
      _db.collection('menu').doc(item.id).set({
        ...item.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<String> uploadMenuImage(
    String itemId,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    final ref = FirebaseStorage.instance.ref('menu_images/$itemId');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> deleteMenuItem(String id) =>
      _db.collection('menu').doc(id).delete();

  // ---- Orders -------------------------------------------------------------

  /// Orders live in a top-level `orders` collection so staff can see all of
  /// them; students filter by userId client-side.
  Stream<QuerySnapshot<Map<String, dynamic>>> orders() => _db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> currentUserOrders() =>
      _db.collection('orders').where('userId', isEqualTo: user.uid).snapshots();

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
        'totalAmount': total,
        'pickupTime': pickupTime,
        'collectionTime': pickupTime,
        'paymentMethod': payment,
        'paymentStatus': payment == 'Card Payment (Demo)'
            ? 'demo_paid'
            : 'pending',
        'notes': notes,
        'specialInstructions': notes,
        'status': 'Pending',
        'orderStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return next;
    });
    return 'SC${number.toString().padLeft(4, '0')}';
  }

  Future<void> setOrderStatus(String orderId, String status) =>
      _db.collection('orders').doc(orderId).update({
        'status': status,
        'orderStatus': status.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setUserRole(String uid, UserRole role) =>
      _db.collection('users').doc(uid).update({'role': role.firestoreValue});
}

final firestoreService = FirestoreService();
