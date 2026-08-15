import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';

class FirebaseService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseFirestore get firestore => _firestore;

  // ─── ANALYTICS EVENTS ──────────────────────────────────────────────────
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      debugPrint('[Analytics] Screen viewed: $screenName');
    } catch (e) {
      debugPrint('[Analytics Error] logScreenView: $e');
    }
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('[Analytics] Logged login with $method');
    } catch (e) {
      debugPrint('[Analytics Error] logLogin: $e');
    }
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
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
      await _analytics.logEvent(
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
  Future<void> syncUserProfile(UserModel user) async {
    try {
      final docId = user.email.trim().toLowerCase();
      if (docId.isEmpty) return;

      await _firestore.collection('users').doc(docId).set({
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'dob': user.dob,
        'city': user.city,
        'rating': user.rating,
        'profilePic': user.profilePic,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[Firestore] User profile synced for ${user.email}');
    } catch (e) {
      debugPrint('[Firestore Error] syncUserProfile: $e');
    }
  }

  Future<void> saveQuizResultToFirestore(String userEmail, Map<String, dynamic> resultData) async {
    try {
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
