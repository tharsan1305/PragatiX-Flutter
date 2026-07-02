// ─────────────────────────────────────────────────────────────────────────────
// Activity module – domain model.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityModel {
  final int id;
  final String name;
  final String description;
  final String frequency;
  final String ownerDepartment;
  final String departmentId;
  final String teacherId;
  final String ownerSubrole;
  final List<String> evidence;
  final String xp;
  final String cap;
  final String type;
  final String justification;

  const ActivityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.ownerDepartment,
    required this.departmentId,
    required this.teacherId,
    required this.ownerSubrole,
    required this.evidence,
    required this.xp,
    required this.cap,
    required this.type,
    required this.justification,
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

    return ActivityModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      ownerDepartment: json['ownerDepartment'] as String? ?? '',
      departmentId: (json['departmentId'] ?? '').toString(),
      teacherId: (json['teacherId'] ?? '').toString(),
      ownerSubrole: json['ownerSubrole'] as String? ?? '',
      evidence: evidenceList,
      xp: (json['xp'] ?? '').toString(),
      cap: (json['cap'] ?? '').toString(),
      type: json['type'] as String? ?? 'Individual',
      justification: json['justification'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'frequency': frequency,
        'ownerDepartment': ownerDepartment,
        'departmentId': departmentId,
        'teacherId': teacherId,
        'ownerSubrole': ownerSubrole,
        'evidence': evidence.join(', '),
        'xp': xp,
        'cap': cap,
        'type': type,
        'justification': justification,
      };

  ActivityModel copyWith({
    int? id,
    String? name,
    String? description,
    String? frequency,
    String? ownerDepartment,
    String? departmentId,
    String? teacherId,
    String? ownerSubrole,
    List<String>? evidence,
    String? xp,
    String? cap,
    String? type,
    String? justification,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      ownerDepartment: ownerDepartment ?? this.ownerDepartment,
      departmentId: departmentId ?? this.departmentId,
      teacherId: teacherId ?? this.teacherId,
      ownerSubrole: ownerSubrole ?? this.ownerSubrole,
      evidence: evidence ?? this.evidence,
      xp: xp ?? this.xp,
      cap: cap ?? this.cap,
      type: type ?? this.type,
      justification: justification ?? this.justification,
    );
  }
}
