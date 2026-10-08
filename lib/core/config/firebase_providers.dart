import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// Firebase SDK entry points. Created lazily, only when a repository needs
/// them, so the app never touches Firebase when it is not configured.
/// Tests override the repositories instead of these.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// Callable functions in the project's region (`africa-south1`).
final functionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: AppConstants.functionsRegion),
);

final messagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

/// The current time. Overridden in tests to check session expiry.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
