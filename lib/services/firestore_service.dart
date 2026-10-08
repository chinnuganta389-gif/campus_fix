import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../models/complaint_model.dart';
import '../models/complaint_history_model.dart';
import '../models/notification_model.dart';
import '../models/activity_log_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==========================================
  // COMPLAINTS
  // ==========================================

  /// Create a new complaint with history entry and notification
  Future<void> createComplaint(ComplaintModel complaint) async {
    try {
      debugPrint('[CampusFix] Firestore complaint write started');
      final batch = _firestore.batch();
      final complaintRef = _firestore
          .collection(AppConstants.collectionComplaints)
          .doc(complaint.complaintId);

      batch.set(complaintRef, complaint.toMap());

      // Initial history record
      final historyRef = complaintRef
          .collection(AppConstants.subcollectionHistory)
          .doc();
      final history = ComplaintHistoryModel(
        id: historyRef.id,
        complaintId: complaint.complaintId,
        action: 'SUBMITTED',
        newStatus: AppConstants.statusPending,
        changedBy: complaint.studentId,
        changedByName: complaint.studentName,
        note: 'Complaint submitted by ${complaint.studentName}',
        createdAt: complaint.createdAt,
      );
      batch.set(historyRef, history.toMap());

      // Student notification
      final notifRef = _firestore.collection(AppConstants.collectionNotifications).doc();
      final notif = NotificationModel(
        id: notifRef.id,
        userId: complaint.studentId,
        title: 'Complaint Registered',
        message: 'Your complaint #${complaint.complaintId} (${complaint.title}) has been registered.',
        type: 'complaint_submitted',
        complaintId: complaint.complaintId,
        createdAt: DateTime.now(),
      );
      batch.set(notifRef, notif.toMap());

      // Activity log
      final logRef = _firestore.collection(AppConstants.collectionActivityLogs).doc();
      final log = ActivityLogModel(
        id: logRef.id,
        actorId: complaint.studentId,
        actorName: complaint.studentName,
        actorRole: AppConstants.roleStudent,
        action: 'COMPLAINT_SUBMITTED',
        targetId: complaint.complaintId,
        description: 'Submitted complaint "${complaint.title}" in ${complaint.category}',
        createdAt: DateTime.now(),
      );
      batch.set(logRef, log.toMap());

      await batch.commit().timeout(
        const Duration(seconds: 15),
      );
      debugPrint('[CampusFix] Firestore complaint write completed');
      debugPrint('[CampusFix] History write completed');
      debugPrint('[CampusFix] Notification write completed');
      debugPrint('[CampusFix] Submission completed');
    } catch (e) {
      debugPrint('[CampusFix] Firestore createComplaint error: $e');
      throw AppException.fromFirebase(e);
    }
  }

  /// Get single complaint by ID
  Future<ComplaintModel?> getComplaint(String complaintId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionComplaints)
          .doc(complaintId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return ComplaintModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  /// Single complaint stream
  Stream<ComplaintModel?> complaintStream(String complaintId) {
    return _firestore
        .collection(AppConstants.collectionComplaints)
        .doc(complaintId)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? ComplaintModel.fromMap(doc.data()!, doc.id)
            : null);
  }

  /// Stream of complaints created by a specific student
  Stream<List<ComplaintModel>> getStudentComplaints(String studentId) {
    return _firestore
        .collection(AppConstants.collectionComplaints)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort descending by createdAt in-memory to avoid mandatory composite index requirements
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream of all complaints (for Staff & Admin)
  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestore
        .collection(AppConstants.collectionComplaints)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream of complaints assigned to a worker
  Stream<List<ComplaintModel>> getWorkerComplaints(String workerId) {
    return _firestore
        .collection(AppConstants.collectionComplaints)
        .where('assignedWorkerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Assign a worker to a complaint
  Future<void> assignWorker({
    required String complaintId,
    required String workerId,
    required String workerName,
    required String actorId,
    required String actorName,
    required String actorRole,
    String? priority,
  }) async {
    try {
      final complaintRef = _firestore
          .collection(AppConstants.collectionComplaints)
          .doc(complaintId);
      final compDoc = await complaintRef.get();
      if (!compDoc.exists) throw AppException('Complaint not found.');

      final oldData = compDoc.data()!;
      final studentId = oldData['studentId'] as String? ?? '';
      final now = DateTime.now();

      final batch = _firestore.batch();

      final updates = <String, dynamic>{
        'assignedWorkerId': workerId,
        'assignedWorkerName': workerName,
        'status': AppConstants.statusAssigned,
        'assignedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      if (priority != null) updates['priority'] = priority;

      batch.update(complaintRef, updates);

      // History
      final histRef = complaintRef.collection(AppConstants.subcollectionHistory).doc();
      batch.set(
        histRef,
        ComplaintHistoryModel(
          id: histRef.id,
          complaintId: complaintId,
          action: 'ASSIGNED',
          oldStatus: oldData['status'],
          newStatus: AppConstants.statusAssigned,
          changedBy: actorId,
          changedByName: actorName,
          note: 'Assigned to worker $workerName by $actorName',
          createdAt: now,
        ).toMap(),
      );

      // Notification to Student
      if (studentId.isNotEmpty) {
        final notifRef = _firestore.collection(AppConstants.collectionNotifications).doc();
        batch.set(
          notifRef,
          NotificationModel(
            id: notifRef.id,
            userId: studentId,
            title: 'Worker Assigned',
            message: 'Worker $workerName has been assigned to your complaint #$complaintId.',
            type: 'complaint_assigned',
            complaintId: complaintId,
            createdAt: now,
          ).toMap(),
        );
      }

      // Notification to Worker
      final workerNotifRef = _firestore.collection(AppConstants.collectionNotifications).doc();
      batch.set(
        workerNotifRef,
        NotificationModel(
          id: workerNotifRef.id,
          userId: workerId,
          title: 'New Task Assigned',
          message: 'You have been assigned complaint #$complaintId: "${oldData['title']}".',
          type: 'complaint_assigned',
          complaintId: complaintId,
          createdAt: now,
        ).toMap(),
      );

      // Activity log
      final logRef = _firestore.collection(AppConstants.collectionActivityLogs).doc();
      batch.set(
        logRef,
        ActivityLogModel(
          id: logRef.id,
          actorId: actorId,
          actorName: actorName,
          actorRole: actorRole,
          action: 'COMPLAINT_ASSIGNED',
          targetId: complaintId,
          description: 'Assigned complaint #$complaintId to $workerName',
          createdAt: now,
        ).toMap(),
      );

      await batch.commit();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  /// Update complaint status (IN_PROGRESS, RESOLVED, REJECTED, etc.)
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String newStatus,
    required String actorId,
    required String actorName,
    required String actorRole,
    String? note,
    String? resolutionImageUrl,
  }) async {
    try {
      final complaintRef = _firestore
          .collection(AppConstants.collectionComplaints)
          .doc(complaintId);
      final compDoc = await complaintRef.get();
      if (!compDoc.exists) throw AppException('Complaint not found.');

      final oldData = compDoc.data()!;
      final oldStatus = oldData['status'] as String? ?? AppConstants.statusPending;
      final studentId = oldData['studentId'] as String? ?? '';
      final now = DateTime.now();

      final batch = _firestore.batch();
      final updates = <String, dynamic>{
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (newStatus == AppConstants.statusInProgress && oldData['startedAt'] == null) {
        updates['startedAt'] = Timestamp.fromDate(now);
      } else if (newStatus == AppConstants.statusResolved) {
        updates['resolvedAt'] = Timestamp.fromDate(now);
        if (note != null) updates['resolutionNote'] = note;
        if (resolutionImageUrl != null) updates['resolutionImageUrl'] = resolutionImageUrl;
      }

      batch.update(complaintRef, updates);

      // History
      final histRef = complaintRef.collection(AppConstants.subcollectionHistory).doc();
      batch.set(
        histRef,
        ComplaintHistoryModel(
          id: histRef.id,
          complaintId: complaintId,
          action: 'STATUS_UPDATED',
          oldStatus: oldStatus,
          newStatus: newStatus,
          changedBy: actorId,
          changedByName: actorName,
          note: note ?? 'Status updated to $newStatus by $actorName',
          createdAt: now,
        ).toMap(),
      );

      // Notification to Student
      if (studentId.isNotEmpty) {
        String notifTitle = 'Status Updated';
        String notifType = 'work_started';
        if (newStatus == AppConstants.statusInProgress) {
          notifTitle = 'Work Started';
          notifType = 'work_started';
        } else if (newStatus == AppConstants.statusResolved) {
          notifTitle = 'Complaint Resolved';
          notifType = 'complaint_resolved';
        } else if (newStatus == AppConstants.statusRejected) {
          notifTitle = 'Complaint Rejected';
          notifType = 'complaint_rejected';
        }

        final notifRef = _firestore.collection(AppConstants.collectionNotifications).doc();
        batch.set(
          notifRef,
          NotificationModel(
            id: notifRef.id,
            userId: studentId,
            title: notifTitle,
            message: 'Complaint #$complaintId is now $newStatus. ${note ?? ""}',
            type: notifType,
            complaintId: complaintId,
            createdAt: now,
          ).toMap(),
        );
      }

      // Activity log
      final logRef = _firestore.collection(AppConstants.collectionActivityLogs).doc();
      batch.set(
        logRef,
        ActivityLogModel(
          id: logRef.id,
          actorId: actorId,
          actorName: actorName,
          actorRole: actorRole,
          action: 'STATUS_UPDATED',
          targetId: complaintId,
          description: 'Changed status of #$complaintId from $oldStatus to $newStatus',
          createdAt: now,
        ).toMap(),
      );

      await batch.commit();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.fromFirebase(e);
    }
  }

  /// Update complaint priority
  Future<void> updateComplaintPriority({
    required String complaintId,
    required String priority,
    required String actorId,
    required String actorName,
    required String actorRole,
  }) async {
    try {
      final complaintRef = _firestore
          .collection(AppConstants.collectionComplaints)
          .doc(complaintId);
      final now = DateTime.now();

      await complaintRef.update({
        'priority': priority,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Activity log
      await _firestore.collection(AppConstants.collectionActivityLogs).add(
        ActivityLogModel(
          id: '',
          actorId: actorId,
          actorName: actorName,
          actorRole: actorRole,
          action: 'PRIORITY_UPDATED',
          targetId: complaintId,
          description: 'Updated priority of #$complaintId to $priority',
          createdAt: now,
        ).toMap(),
      );
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  /// Stream history of a complaint for the visual timeline
  Stream<List<ComplaintHistoryModel>> getComplaintHistory(String complaintId) {
    return _firestore
        .collection(AppConstants.collectionComplaints)
        .doc(complaintId)
        .collection(AppConstants.subcollectionHistory)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ComplaintHistoryModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  // ==========================================
  // USERS & WORKERS
  // ==========================================

  /// Stream of all users or filtered by role
  Stream<List<UserModel>> getUsersStream({String? role}) {
    Query query = _firestore.collection(AppConstants.collectionUsers);
    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// Stream of workers
  Stream<List<UserModel>> getWorkersStream() {
    return getUsersStream(role: AppConstants.roleWorker);
  }

  /// Admin toggle active state of user
  Future<void> setUserActiveStatus({
    required String uid,
    required bool isActive,
    required String adminId,
    required String adminName,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection(AppConstants.collectionUsers).doc(uid).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(now),
      });

      await _firestore.collection(AppConstants.collectionActivityLogs).add(
        ActivityLogModel(
          id: '',
          actorId: adminId,
          actorName: adminName,
          actorRole: AppConstants.roleAdmin,
          action: isActive ? 'USER_ACTIVATED' : 'USER_DEACTIVATED',
          targetId: uid,
          description: '${isActive ? "Activated" : "Deactivated"} user $uid',
          createdAt: now,
        ).toMap(),
      );
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  /// Admin update user role
  Future<void> updateUserRole({
    required String uid,
    required String newRole,
    required String adminId,
    required String adminName,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection(AppConstants.collectionUsers).doc(uid).update({
        'role': newRole,
        'updatedAt': Timestamp.fromDate(now),
      });

      await _firestore.collection(AppConstants.collectionActivityLogs).add(
        ActivityLogModel(
          id: '',
          actorId: adminId,
          actorName: adminName,
          actorRole: AppConstants.roleAdmin,
          action: 'USER_ROLE_UPDATED',
          targetId: uid,
          description: 'Updated user $uid role to $newRole',
          createdAt: now,
        ).toMap(),
      );
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================

  /// Stream of user notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Mark single notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionNotifications)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionNotifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  // ==========================================
  // ACTIVITY LOGS
  // ==========================================

  /// Stream of system activity logs
  Stream<List<ActivityLogModel>> getActivityLogsStream() {
    return _firestore
        .collection(AppConstants.collectionActivityLogs)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
