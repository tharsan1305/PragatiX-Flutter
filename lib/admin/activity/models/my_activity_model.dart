// ─────────────────────────────────────────────────────────────────────────────
// MyActivity Model – domain model representing assignments for the active user.
// ─────────────────────────────────────────────────────────────────────────────

import 'activity_model.dart';

class MyActivityModel {
  final int activityId;
  final String name;
  final String description;
  final String frequency;
  final List<String> evidence;
  final String xp;
  final String cap;
  final String type;
  final String justification;
  final int? departmentId;
  final String departmentName;
  final int? sectionId;
  final String sectionName;
  final String assignedBy;
  final String assignedAt;

  const MyActivityModel({
    required this.activityId,
    required this.name,
    required this.description,
    required this.frequency,
    required this.evidence,
    required this.xp,
    required this.cap,
    required this.type,
    required this.justification,
    this.departmentId,
    required this.departmentName,
    this.sectionId,
    required this.sectionName,
    required this.assignedBy,
    required this.assignedAt,
  });

  factory MyActivityModel.fromJson(Map<String, dynamic> json) {
    final raw = json['evidence'];
    final List<String> evidenceList;
    if (raw is List) {
      evidenceList = raw.map((e) => e.toString()).toList();
    } else if (raw is String && raw.isNotEmpty) {
      evidenceList = raw.split(',').map((e) => e.trim()).toList();
    } else {
      evidenceList = [];
    }

    return MyActivityModel(
      activityId: (json['activityId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      evidence: evidenceList,
      xp: (json['xp'] ?? '').toString(),
      cap: (json['cap'] ?? '').toString(),
      type: json['type'] as String? ?? 'Individual',
      justification: json['justification'] as String? ?? '',
      departmentId: (json['departmentId'] as num?)?.toInt(),
      departmentName: json['departmentName'] as String? ?? '',
      sectionId: (json['sectionId'] as num?)?.toInt(),
      sectionName: json['sectionName'] as String? ?? '',
      assignedBy: json['assignedBy'] as String? ?? '',
      assignedAt: json['assignedAt'] as String? ?? '',
    );
  }

  ActivityModel toActivityModel() {
    return ActivityModel(
      id: activityId,
      name: name,
      description: description,
      frequency: frequency,
      ownerDepartment: departmentName,
      departmentId: departmentId?.toString() ?? '',
      teacherId: '',
      ownerSubrole: '',
      evidence: evidence,
      xp: xp,
      cap: cap,
      type: type,
      justification: justification,
      assignmentSummary: [
        {
          'section': sectionId != null ? sectionName : null,
          'teacher': 'Assigned to me',
          'teacherName': 'Assigned to me',
        }
      ],
    );
  }
}
