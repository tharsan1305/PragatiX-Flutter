// ─────────────────────────────────────────────────────────────────────────────
// Activity module – domain model.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityModel {
  final int id;
  final String name;
  final String description;
  final String ownerDepartment;
  final String departmentId;
  final String teacherId;
  final String ownerSubrole;
  final List<String> evidence;
  final String xp;
  final String type;
  final String justification;
  final List<Map<String, dynamic>> assignmentSummary;
  final String xpCategory;
  final int displayOrder;
  final String status;
  final int awardXp;
  final String awardType;
  // ── Refactored Award Rules ─────────────────────────────────────────────────
  final int cap;             // max awards per frequency window
  final String awardFrequency; // One Time | Daily | Weekly | Monthly | Manual
  final List<String> awardDays; // working days (Weekly only)

  // Backward-compat aliases
  String get frequency => awardFrequency;
  String get resetPeriod => awardFrequency;
  int get maximumAwards => cap;
  bool get repeatAllowed => awardFrequency.toLowerCase() != 'one time';

  const ActivityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerDepartment,
    required this.departmentId,
    required this.teacherId,
    required this.ownerSubrole,
    required this.evidence,
    required this.xp,
    required this.type,
    required this.justification,
    required this.assignmentSummary,
    required this.xpCategory,
    required this.displayOrder,
    required this.status,
    required this.awardXp,
    required this.awardType,
    required this.cap,
    required this.awardFrequency,
    required this.awardDays,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final raw = json['evidence'];
    final List<String> evidenceList;
    if (raw is List) {
      evidenceList = raw.map((e) => e.toString()).toList();
    } else if (raw is String && raw.isNotEmpty) {
      evidenceList = raw.split(',').map((e) => e.trim()).toList();
    } else {
      evidenceList = [];
    }

    final rawSummary = json['assignmentSummary'];
    final List<Map<String, dynamic>> summaryList;
    if (rawSummary is List) {
      summaryList = rawSummary.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      summaryList = [];
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

    return ActivityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ownerDepartment: json['ownerDepartment'] as String? ?? '',
      departmentId: (json['departmentId'] ?? '').toString(),
      teacherId: (json['teacherId'] ?? '').toString(),
      ownerSubrole: json['ownerSubrole'] as String? ?? '',
      evidence: evidenceList,
      xp: parsedAwardXp.toString(),
      type: json['type'] as String? ?? 'Individual',
      justification: json['justification'] as String? ?? '',
      assignmentSummary: summaryList,
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

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'ownerDepartment': ownerDepartment,
        'departmentId': departmentId,
        'teacherId': teacherId,
        'ownerSubrole': ownerSubrole,
        'evidence': evidence.join(', '),
        'xp': awardXp.toString(),
        'type': type,
        'justification': justification,
        'assignmentSummary': assignmentSummary,
        'xpCategory': xpCategory,
        'displayOrder': displayOrder,
        'status': status,
        'awardXp': awardXp,
        'awardType': awardType,
        'cap': cap,
        'awardFrequency': awardFrequency,
        'awardDays': awardDays,
      };

  ActivityModel copyWith({
    int? id,
    String? name,
    String? description,
    String? ownerDepartment,
    String? departmentId,
    String? teacherId,
    String? ownerSubrole,
    List<String>? evidence,
    String? xp,
    String? type,
    String? justification,
    List<Map<String, dynamic>>? assignmentSummary,
    String? xpCategory,
    int? displayOrder,
    String? status,
    int? awardXp,
    String? awardType,
    int? cap,
    String? awardFrequency,
    List<String>? awardDays,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerDepartment: ownerDepartment ?? this.ownerDepartment,
      departmentId: departmentId ?? this.departmentId,
      teacherId: teacherId ?? this.teacherId,
      ownerSubrole: ownerSubrole ?? this.ownerSubrole,
      evidence: evidence ?? this.evidence,
      xp: xp ?? this.xp,
      type: type ?? this.type,
      justification: justification ?? this.justification,
      assignmentSummary: assignmentSummary ?? this.assignmentSummary,
      xpCategory: xpCategory ?? this.xpCategory,
      displayOrder: displayOrder ?? this.displayOrder,
      status: status ?? this.status,
      awardXp: awardXp ?? this.awardXp,
      awardType: awardType ?? this.awardType,
      cap: cap ?? this.cap,
      awardFrequency: awardFrequency ?? this.awardFrequency,
      awardDays: awardDays ?? this.awardDays,
    );
  }
}
