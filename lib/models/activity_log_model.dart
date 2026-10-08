import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogModel {
  final String id;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action;
  final String targetId;
  final String description;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.targetId,
    required this.description,
    required this.createdAt,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ActivityLogModel(
      id: id,
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? '',
      actorRole: map['actorRole'] ?? '',
      action: map['action'] ?? '',
      targetId: map['targetId'] ?? '',
      description: map['description'] ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'action': action,
      'targetId': targetId,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
