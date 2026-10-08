import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/complaint_model.dart';
import '../models/notification_model.dart';
import '../models/activity_log_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'campus_location_service.dart';

// Service Providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final campusLocationServiceProvider = Provider<CampusLocationService>((ref) {
  return CampusLocationService();
});

/// Developer Testing Mode for Geofencing (DEBUG MODE ONLY)
final devLocationModeProvider = StateProvider<DevLocationTestingMode>((ref) {
  return DevLocationTestingMode.realGps;
});

// Auth Stream Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current User Profile Provider
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    return Stream.value(null);
  }
  final authService = ref.watch(authServiceProvider);
  return authService.userProfileStream(user.uid);
});

// Student Complaints Stream Provider
final studentComplaintsProvider = StreamProvider<List<ComplaintModel>>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).value;
  if (userProfile == null) {
    return Stream.value([]);
  }
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getStudentComplaints(userProfile.uid);
});

// All Complaints Stream Provider (Staff & Admin)
final allComplaintsProvider = StreamProvider<List<ComplaintModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getAllComplaints();
});

// Worker Complaints Stream Provider
final workerComplaintsProvider = StreamProvider<List<ComplaintModel>>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).value;
  if (userProfile == null) {
    return Stream.value([]);
  }
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getWorkerComplaints(userProfile.uid);
});

// Workers List Stream Provider (for assigning tasks)
final workersListProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getWorkersStream();
});

// All Users List Stream Provider (for Admin)
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getUsersStream();
});

// Current User Notifications Stream Provider
final userNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider).value;
  if (userProfile == null) {
    return Stream.value([]);
  }
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getUserNotifications(userProfile.uid);
});

// Unread Notifications Count Provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(userNotificationsProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});

// Activity Logs Provider
final activityLogsProvider = StreamProvider<List<ActivityLogModel>>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getActivityLogsStream();
});
