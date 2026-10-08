import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'CampusFix';
  static const String appVersion = '2.0.0';
  static const String appTagline = 'Fixing Campus. Improving Life.';

  // SharedPreferences Keys
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyRememberUser = 'remember_user_email';

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionComplaints = 'complaints';
  static const String subcollectionHistory = 'history';
  static const String collectionNotifications = 'notifications';
  static const String collectionActivityLogs = 'activity_logs';

  // Roles
  static const String roleStudent = 'student';
  static const String roleStaff = 'staff';
  static const String roleWorker = 'worker';
  static const String roleAdmin = 'admin';

  // Complaint Statuses
  static const String statusPending = 'PENDING';
  static const String statusAssigned = 'ASSIGNED';
  static const String statusInProgress = 'IN_PROGRESS';
  static const String statusResolved = 'RESOLVED';
  static const String statusRejected = 'REJECTED';
  static const String statusCancelled = 'CANCELLED';

  static const List<String> allStatuses = [
    statusPending,
    statusAssigned,
    statusInProgress,
    statusResolved,
    statusRejected,
    statusCancelled,
  ];

  // Complaint Priorities
  static const String priorityLow = 'LOW';
  static const String priorityMedium = 'MEDIUM';
  static const String priorityHigh = 'HIGH';
  static const String priorityUrgent = 'URGENT';

  static const List<String> allPriorities = [
    priorityLow,
    priorityMedium,
    priorityHigh,
    priorityUrgent,
  ];

  // Categories with Icons
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Electrical', 'icon': Icons.bolt_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Plumbing', 'icon': Icons.water_drop_rounded, 'color': Color(0xFF0284C7)},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Water', 'icon': Icons.local_drink_rounded, 'color': Color(0xFF06B6D4)},
    {'name': 'Furniture', 'icon': Icons.chair_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Internet', 'icon': Icons.wifi_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'Classroom', 'icon': Icons.meeting_room_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'Hostel', 'icon': Icons.bed_rounded, 'color': Color(0xFFF97316)},
    {'name': 'Washroom', 'icon': Icons.wash_rounded, 'color': Color(0xFF6366F1)},
    {'name': 'Infrastructure', 'icon': Icons.apartment_rounded, 'color': Color(0xFF64748B)},
    {'name': 'Other', 'icon': Icons.category_rounded, 'color': Color(0xFF475569)},
  ];

  // Campus Departments
  static const List<String> departments = [
    'Computer Science & Engineering',
    'Electronics & Communication',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical & Electronics',
    'Information Technology',
    'Management Studies (MBA)',
    'Sciences & Humanities',
    'Campus Administration',
    'Hostel Management',
    'Other',
  ];
}
