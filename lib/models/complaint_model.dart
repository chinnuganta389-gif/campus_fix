import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId; // e.g. CF-2026-000123
  final String studentId;
  final String studentName;
  final String title;
  final String description;
  final String category;
  final String location;
  final String? imageUrl;
  final String status; // PENDING, ASSIGNED, IN_PROGRESS, RESOLVED, REJECTED, CANCELLED
  final String? assignedWorkerId;
  final String? assignedWorkerName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final String? resolutionImageUrl;
  final String priority; // LOW, MEDIUM, HIGH, URGENT
  final Map<String, dynamic>? locationData; // Geofence & GPS verification metadata

  ComplaintModel({
    required this.complaintId,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.imageUrl,
    this.status = 'PENDING',
    this.assignedWorkerId,
    this.assignedWorkerName,
    required this.createdAt,
    required this.updatedAt,
    this.assignedAt,
    this.startedAt,
    this.resolvedAt,
    this.resolutionNote,
    this.resolutionImageUrl,
    this.priority = 'MEDIUM',
    this.locationData,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ComplaintModel(
      complaintId: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'],
      status: map['status'] ?? 'PENDING',
      assignedWorkerId: map['assignedWorkerId'],
      assignedWorkerName: map['assignedWorkerName'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      assignedAt: parseOptionalDate(map['assignedAt']),
      startedAt: parseOptionalDate(map['startedAt']),
      resolvedAt: parseOptionalDate(map['resolvedAt']),
      resolutionNote: map['resolutionNote'],
      resolutionImageUrl: map['resolutionImageUrl'],
      priority: map['priority'] ?? 'MEDIUM',
      locationData: map['locationData'] != null ? Map<String, dynamic>.from(map['locationData']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'studentId': studentId,
      'studentName': studentName,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': status,
      if (assignedWorkerId != null) 'assignedWorkerId': assignedWorkerId,
      if (assignedWorkerName != null) 'assignedWorkerName': assignedWorkerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (assignedAt != null) 'assignedAt': Timestamp.fromDate(assignedAt!),
      if (startedAt != null) 'startedAt': Timestamp.fromDate(startedAt!),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      if (resolutionNote != null) 'resolutionNote': resolutionNote,
      if (resolutionImageUrl != null) 'resolutionImageUrl': resolutionImageUrl,
      'priority': priority,
      if (locationData != null) 'locationData': locationData,
    };
  }

  ComplaintModel copyWith({
    String? title,
    String? description,
    String? category,
    String? location,
    String? imageUrl,
    String? status,
    String? assignedWorkerId,
    String? assignedWorkerName,
    DateTime? updatedAt,
    DateTime? assignedAt,
    DateTime? startedAt,
    DateTime? resolvedAt,
    String? resolutionNote,
    String? resolutionImageUrl,
    String? priority,
    Map<String, dynamic>? locationData,
  }) {
    return ComplaintModel(
      complaintId: complaintId,
      studentId: studentId,
      studentName: studentName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      assignedAt: assignedAt ?? this.assignedAt,
      startedAt: startedAt ?? this.startedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      resolutionImageUrl: resolutionImageUrl ?? this.resolutionImageUrl,
      priority: priority ?? this.priority,
      locationData: locationData ?? this.locationData,
    );
  }
}
