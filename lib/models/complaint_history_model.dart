import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintHistoryModel {
  final String id;
  final String complaintId;
  final String action; // CREATED, ASSIGNED, STATUS_UPDATED, NOTE_ADDED, RESOLVED, REJECTED
  final String? oldStatus;
  final String? newStatus;
  final String changedBy;
  final String changedByName;
  final String? note;
  final DateTime createdAt;

  ComplaintHistoryModel({
    required this.id,
    required this.complaintId,
    required this.action,
    this.oldStatus,
    this.newStatus,
    required this.changedBy,
    required this.changedByName,
    this.note,
    required this.createdAt,
  });

  factory ComplaintHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ComplaintHistoryModel(
      id: id,
      complaintId: map['complaintId'] ?? '',
      action: map['action'] ?? '',
      oldStatus: map['oldStatus'],
      newStatus: map['newStatus'],
      changedBy: map['changedBy'] ?? '',
      changedByName: map['changedByName'] ?? '',
      note: map['note'],
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'action': action,
      if (oldStatus != null) 'oldStatus': oldStatus,
      if (newStatus != null) 'newStatus': newStatus,
      'changedBy': changedBy,
      'changedByName': changedByName,
      if (note != null) 'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
