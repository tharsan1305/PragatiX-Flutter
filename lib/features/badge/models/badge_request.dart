class BadgeRequest {
  final int id;
  final int studentId;
  final String studentName;
  final String regNo;
  final int badgeId;
  final String badgeName;
  final String badgeIcon;
  final String departmentName;
  final String sectionName;
  final String status;
  final String requestedAt;
  final String? reviewedAt;
  final String? reviewedBy;
  final String? remarks;
  final String? proofLink;

  BadgeRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.regNo,
    required this.badgeId,
    required this.badgeName,
    required this.badgeIcon,
    required this.departmentName,
    required this.sectionName,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.remarks,
    this.proofLink,
  });

  factory BadgeRequest.fromJson(Map<String, dynamic> json) {
    return BadgeRequest(
      id: json['id'],
      studentId: json['studentId'],
      studentName: json['studentName'] ?? '',
      regNo: json['regNo'] ?? '',
      badgeId: json['badgeId'],
      badgeName: json['badgeName'] ?? '',
      badgeIcon: json['badgeIcon'] ?? '',
      departmentName: json['departmentName'] ?? '',
      sectionName: json['sectionName'] ?? '',
      status: json['status'] ?? 'PENDING',
      requestedAt: json['requestedAt'] ?? '',
      reviewedAt: json['reviewedAt'],
      reviewedBy: json['reviewedBy'],
      remarks: json['remarks'],
      proofLink: json['proofLink'],
    );
  }
}
