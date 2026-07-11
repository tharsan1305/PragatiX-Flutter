import 'activity_model.dart';

class MyActivityModel {
  final int activityId;
  final String name;
  final String description;
  final List<String> evidence;
  final String xp;
  final String type;
  final String justification;
  final int? departmentId;
  final String departmentName;
  final int? sectionId;
  final String sectionName;
  final String assignedBy;
  final String assignedAt;
  final String xpCategory;
  final int displayOrder;
  final String status;
  final int awardXp;
  final String awardType;
  // ── Refactored Award Rules ─────────────────────────────────────────────────
  final int cap;               // max awards per frequency window
  final String awardFrequency; // One Time | Daily | Weekly | Monthly | Manual
  final List<String> awardDays; // working days (Weekly only)

  // Backward-compat aliases
  String get frequency => awardFrequency;
  String get resetPeriod => awardFrequency;
  int get maximumAwards => cap;
  bool get repeatAllowed => awardFrequency.toLowerCase() != 'one time';

  const MyActivityModel({
    required this.activityId,
    required this.name,
    required this.description,
    required this.evidence,
    required this.xp,
    required this.type,
    required this.justification,
    this.departmentId,
    required this.departmentName,
    this.sectionId,
    required this.sectionName,
    required this.assignedBy,
    required this.assignedAt,
    required this.xpCategory,
    required this.displayOrder,
    required this.status,
    required this.awardXp,
    required this.awardType,
    required this.cap,
    required this.awardFrequency,
    required this.awardDays,
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

    final parsedAwardXp = (json['awardXp'] as num?)?.toInt() ??
        (json['xp'] != null ? int.tryParse(json['xp'].toString()) ?? 0 : 0);

    // Award Frequency — support both new and legacy field names
    final parsedFrequency = (json['awardFrequency'] as String?)?.isNotEmpty == true
        ? json['awardFrequency'] as String
        : (json['resetPeriod'] as String?)?.isNotEmpty == true
            ? json['resetPeriod'] as String
            : (json['frequency'] as String?)?.isNotEmpty == true
                ? json['frequency'] as String
                : 'One Time';

    // Cap — support both new and legacy field names
    final parsedCap = (json['cap'] is num)
        ? (json['cap'] as num).toInt()
        : (json['maximumAwards'] is num)
            ? (json['maximumAwards'] as num).toInt()
            : int.tryParse(json['cap']?.toString() ?? '1') ?? 1;

    // Award Days
    final rawDays = json['awardDays'];
    final List<String> parsedDays;
    if (rawDays is List) {
      parsedDays = rawDays.map((e) => e.toString()).toList();
    } else if (rawDays is String && rawDays.isNotEmpty) {
      parsedDays = rawDays.split(',').map((e) => e.trim()).toList();
    } else {
      parsedDays = [];
    }

    return MyActivityModel(
      activityId: (json['activityId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      evidence: evidenceList,
      xp: parsedAwardXp.toString(),
      type: json['type'] as String? ?? 'Individual',
      justification: json['justification'] as String? ?? '',
      departmentId: (json['departmentId'] as num?)?.toInt(),
      departmentName: json['departmentName'] as String? ?? '',
      sectionId: (json['sectionId'] as num?)?.toInt(),
      sectionName: json['sectionName'] as String? ?? '',
      assignedBy: json['assignedBy'] as String? ?? '',
      assignedAt: json['assignedAt'] as String? ?? '',
      xpCategory: json['xpCategory'] as String? ?? 'Academic',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'ACTIVE',
      awardXp: parsedAwardXp,
      awardType: json['awardType'] as String? ?? 'Fixed XP',
      cap: parsedCap,
      awardFrequency: parsedFrequency,
      awardDays: parsedDays,
    );
  }

  ActivityModel toActivityModel() {
    return ActivityModel(
      id: activityId,
      name: name,
      description: description,
      ownerDepartment: departmentName,
      departmentId: departmentId?.toString() ?? '',
      teacherId: '',
      ownerSubrole: '',
      evidence: evidence,
      xp: xp,
      type: type,
      justification: justification,
      assignmentSummary: [
        {
          'section': sectionId != null ? sectionName : null,
          'teacher': 'Assigned to me',
          'teacherName': 'Assigned to me',
        }
      ],
      xpCategory: xpCategory,
      displayOrder: displayOrder,
      status: status,
      awardXp: awardXp,
      awardType: awardType,
      cap: cap,
      awardFrequency: awardFrequency,
      awardDays: awardDays,
    );
  }
}
