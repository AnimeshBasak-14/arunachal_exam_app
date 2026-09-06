import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';

class FirebaseService {
  final FirebaseAnalytics? _analytics;
  final FirebaseFirestore? _firestore;

  FirebaseService({
    FirebaseAnalytics? analytics,
    FirebaseFirestore? firestore,
  })  : _analytics = analytics ?? _safeAnalytics(),
        _firestore = firestore ?? _safeFirestore();

  static FirebaseAnalytics? _safeAnalytics() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAnalytics.instance;
      }
    } catch (_) {}
    return null;
  }

  static FirebaseFirestore? _safeFirestore() {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  FirebaseAnalytics? get analytics => _analytics;
  FirebaseFirestore? get firestore => _firestore;

  // ─── ANALYTICS EVENTS ──────────────────────────────────────────────────
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics?.logScreenView(screenName: screenName);
      debugPrint('[Analytics] Screen viewed: $screenName');
    } catch (e) {
      debugPrint('[Analytics Error] logScreenView: $e');
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
      debugPrint('[Analytics] Logged login with $method');
    } catch (e) {
      debugPrint('[Analytics Error] logLogin: $e');
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics?.logSignUp(signUpMethod: method);
      debugPrint('[Analytics] Logged sign up with $method');
    } catch (e) {
      debugPrint('[Analytics Error] logSignUp: $e');
    }
  }

  Future<void> logQuizCompleted({
    required String examCode,
    required double score,
    required double maxScore,
    required int trophiesChange,
    required int timeTakenSeconds,
    required String rankTier,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'quiz_completed',
        parameters: {
          'exam_code': examCode,
          'score': score,
          'max_score': maxScore,
          'trophies_delta': trophiesChange,
          'time_taken_seconds': timeTakenSeconds,
          'rank_tier': rankTier,
        },
      );
      debugPrint('[Analytics] Logged quiz_completed event');
    } catch (e) {
      debugPrint('[Analytics Error] logQuizCompleted: $e');
    }
  }

  // ─── FIRESTORE DATABASE SYNC ──────────────────────────────────────────
  Future<UserModel?> fetchUserProfile(String email) async {
    try {
      if (_firestore == null) return null;
      final docId = email.trim().toLowerCase();
      if (docId.isEmpty) return null;

      final doc = await _firestore.collection('users').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final name = (data['name'] as String?)?.trim() ?? '';
        return UserModel(
          name: name.isNotEmpty ? name : email.split('@')[0],
          email: data['email'] as String? ?? email,
          phone: data['phone'] as String? ?? '',
          dob: data['dob'] as String? ?? '2000-01-01',
          city: data['city'] as String? ?? 'Itanagar',
          rating: (data['rating'] as num?)?.toInt() ?? 0,
          profilePic: data['profilePic'] as String? ?? 'avatar_green',
        );
      }
    } catch (e) {
      debugPrint('[Firestore Error] fetchUserProfile: $e');
    }
    return null;
  }

  Future<void> syncUserProfile(UserModel user) async {
    try {
      if (_firestore == null) return;
      final docId = user.email.trim().toLowerCase();
      if (docId.isEmpty) return;

      final Map<String, dynamic> updateData = {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'dob': user.dob,
        'city': user.city,
        'lastActive': FieldValue.serverTimestamp(),
      };

      if (user.rating > 0) {
        updateData['rating'] = user.rating;
      }
      if (user.profilePic != null && user.profilePic!.isNotEmpty) {
        updateData['profilePic'] = user.profilePic;
      }

      await _firestore.collection('users').doc(docId).set(
            updateData,
            SetOptions(merge: true),
          );

      debugPrint('[Firestore] User profile synced for ${user.email}');
    } catch (e) {
      debugPrint('[Firestore Error] syncUserProfile: $e');
    }
  }

  Future<void> saveQuizResultToFirestore(
      String userEmail, Map<String, dynamic> resultData) async {
    try {
      if (_firestore == null) return;
      final cleanEmail = userEmail.trim().toLowerCase();
      if (cleanEmail.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(cleanEmail)
          .collection('quiz_history')
          .add({
        ...resultData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('[Firestore] Quiz result saved to Firestore subcollection');
    } catch (e) {
      debugPrint('[Firestore Error] saveQuizResultToFirestore: $e');
    }
  }
}

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
