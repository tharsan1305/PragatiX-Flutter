import 'student_attendance_list_item.dart';

class AdminAttendanceSummary {
  final int totalStudents;
  final int totalPresent;
  final int totalAbsent;
  final double attendancePercentage;
  final List<StudentAttendanceListItem> presentStudents;
  final List<StudentAttendanceListItem> absentStudents;

  AdminAttendanceSummary({
    required this.totalStudents,
    required this.totalPresent,
    required this.totalAbsent,
    required this.attendancePercentage,
    required this.presentStudents,
    required this.absentStudents,
  });

  factory AdminAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceSummary(
      totalStudents: json['totalStudents'] as int,
      totalPresent: json['totalPresent'] as int,
      totalAbsent: json['totalAbsent'] as int,
      attendancePercentage: (json['attendancePercentage'] as num).toDouble(),
      presentStudents: (json['presentStudents'] as List)
          .map((e) => StudentAttendanceListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      absentStudents: (json['absentStudents'] as List)
          .map((e) => StudentAttendanceListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
