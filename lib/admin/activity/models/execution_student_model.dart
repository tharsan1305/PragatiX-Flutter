class ExecutionStudentModel {
  final int id;
  final String fullName;
  final String studentId;
  final int regNo;
  final String departmentName;
  final String sectionName;
  final int totalXp;
  final int score;

  ExecutionStudentModel({
    required this.id,
    required this.fullName,
    required this.studentId,
    required this.regNo,
    required this.departmentName,
    required this.sectionName,
    required this.totalXp,
    required this.score,
  });

  factory ExecutionStudentModel.fromJson(Map<String, dynamic> json) {
    return ExecutionStudentModel(
      id: json['id'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      regNo: json['regNo'] as int? ?? 0,
      departmentName: json['departmentName'] as String? ?? '',
      sectionName: json['sectionName'] as String? ?? '',
      totalXp: json['totalXp'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'studentId': studentId,
      'regNo': regNo,
      'departmentName': departmentName,
      'sectionName': sectionName,
      'totalXp': totalXp,
      'score': score,
    };
  }
}

class ActivityExecutionDetailModel {
  final int id;
  final String name;
  final String description;
  final String department;
  final List<String> evidence;
  final String frequency;
  final String type;

  ActivityExecutionDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.department,
    required this.evidence,
    required this.frequency,
    required this.type,
  });

  factory ActivityExecutionDetailModel.fromJson(Map<String, dynamic> json) {
    final listRaw = json['evidence'] as List<dynamic>? ?? [];
    return ActivityExecutionDetailModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      department: json['department'] as String? ?? '',
      evidence: listRaw.map((e) => e.toString()).toList(),
      frequency: json['frequency'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }
}

class AssignmentExecutionDetailModel {
  final int id;
  final String assignedBy;
  final String assignedAt;

  AssignmentExecutionDetailModel({
    required this.id,
    required this.assignedBy,
    required this.assignedAt,
  });

  factory AssignmentExecutionDetailModel.fromJson(Map<String, dynamic> json) {
    return AssignmentExecutionDetailModel(
      id: json['id'] as int? ?? 0,
      assignedBy: json['assignedBy'] as String? ?? '',
      assignedAt: json['assignedAt'] as String? ?? '',
    );
  }
}

class MyActivityStudentsResponseModel {
  final ActivityExecutionDetailModel activity;
  final List<ExecutionStudentModel> students;
  final int xpLimit;
  final AssignmentExecutionDetailModel assignment;

  MyActivityStudentsResponseModel({
    required this.activity,
    required this.students,
    required this.xpLimit,
    required this.assignment,
  });

  factory MyActivityStudentsResponseModel.fromJson(Map<String, dynamic> json) {
    final studentsRaw = json['students'] as List<dynamic>? ?? [];
    return MyActivityStudentsResponseModel(
      activity: ActivityExecutionDetailModel.fromJson(json['activity'] as Map<String, dynamic>? ?? {}),
      students: studentsRaw.map((e) => ExecutionStudentModel.fromJson(e as Map<String, dynamic>)).toList(),
      xpLimit: json['xpLimit'] as int? ?? 0,
      assignment: AssignmentExecutionDetailModel.fromJson(json['assignment'] as Map<String, dynamic>? ?? {}),
    );
  }
}
