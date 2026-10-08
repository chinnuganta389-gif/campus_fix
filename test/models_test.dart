import 'package:flutter_test/flutter_test.dart';
import 'package:campus_fix/models/user_model.dart';
import 'package:campus_fix/models/complaint_model.dart';
import 'package:campus_fix/models/complaint_history_model.dart';
import 'package:campus_fix/models/notification_model.dart';
import 'package:campus_fix/core/utils/validators.dart';
import 'package:campus_fix/core/utils/id_generator.dart';
import 'package:campus_fix/core/constants/app_constants.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel properties and role getters', () {
      final user = UserModel(
        uid: 'user_123',
        name: 'Alex Johnson',
        email: 'alex@college.edu',
        phone: '9876543210',
        role: AppConstants.roleStudent,
        department: 'Computer Science',
        studentId: 'CS2026',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(user.isStudent, true);
      expect(user.isAdmin, false);
      expect(user.isStaff, false);
      expect(user.isWorker, false);
      expect(user.name, 'Alex Johnson');
      expect(user.isActive, true);

      final worker = user.copyWith(role: AppConstants.roleWorker);
      expect(worker.isWorker, true);
      expect(worker.isStudent, false);
    });

    test('UserModel toMap and fromMap serialization', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'uid_999',
        name: 'Dr. Smith',
        email: 'smith@college.edu',
        phone: '1234567890',
        role: AppConstants.roleStaff,
        department: 'Facilities',
        createdAt: now,
        updatedAt: now,
      );

      final map = user.toMap();
      expect(map['role'], 'staff');
      expect(map['department'], 'Facilities');
      expect(map['name'], 'Dr. Smith');
    });
  });

  group('ComplaintModel & History Tests', () {
    test('ComplaintModel properties and copyWith', () {
      final now = DateTime.now();
      final complaint = ComplaintModel(
        complaintId: 'CF-2026-000101',
        studentId: 's_1',
        studentName: 'John',
        title: 'Water Leakage in Lab',
        description: 'Pipes leaking on 2nd floor',
        category: 'Plumbing',
        location: 'Civil Lab Room 204',
        status: AppConstants.statusPending,
        createdAt: now,
        updatedAt: now,
        priority: AppConstants.priorityUrgent,
      );

      expect(complaint.complaintId, 'CF-2026-000101');
      expect(complaint.category, 'Plumbing');
      expect(complaint.priority, AppConstants.priorityUrgent);
      expect(complaint.status, AppConstants.statusPending);

      final assigned = complaint.copyWith(
        status: AppConstants.statusAssigned,
        assignedWorkerId: 'w_1',
        assignedWorkerName: 'Bob the Plumber',
      );
      expect(assigned.status, AppConstants.statusAssigned);
      expect(assigned.assignedWorkerName, 'Bob the Plumber');
    });

    test('ComplaintHistoryModel serialization', () {
      final now = DateTime.now();
      final history = ComplaintHistoryModel(
        id: 'h_1',
        complaintId: 'CF-2026-000101',
        action: 'ASSIGNED',
        oldStatus: AppConstants.statusPending,
        newStatus: AppConstants.statusAssigned,
        changedBy: 'admin_1',
        changedByName: 'Admin Sarah',
        note: 'Assigned to Bob',
        createdAt: now,
      );

      final map = history.toMap();
      expect(map['action'], 'ASSIGNED');
      expect(map['oldStatus'], AppConstants.statusPending);
      expect(map['newStatus'], AppConstants.statusAssigned);
      expect(map['changedByName'], 'Admin Sarah');
    });
  });

  group('NotificationModel Tests', () {
    test('NotificationModel read state and serialization', () {
      final now = DateTime.now();
      final notif = NotificationModel(
        id: 'n_1',
        userId: 'u_1',
        title: 'Task Assigned',
        message: 'You have a new maintenance task',
        type: 'complaint_assigned',
        complaintId: 'CF-2026-000101',
        createdAt: now,
      );

      expect(notif.isRead, false);
      final readNotif = notif.copyWith(isRead: true);
      expect(readNotif.isRead, true);
    });
  });

  group('Validators & ID Generator Tests', () {
    test('Email validator accepts valid emails and rejects invalid', () {
      expect(Validators.validateEmail('user@campus.edu'), isNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail('test@test'), isNotNull);
    });

    test('Password validator requires minimum 6 characters', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('pass'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('Phone validator verifies format', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('123'), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
    });

    test('IdGenerator creates standard CF-YEAR-XXXXXX format', () {
      final id1 = IdGenerator.generateComplaintId();
      final id2 = IdGenerator.generateComplaintId();

      expect(id1.startsWith('CF-${DateTime.now().year}-'), true);
      expect(id2.startsWith('CF-${DateTime.now().year}-'), true);
      expect(id1.length >= 14, true);
    });
  });
}
