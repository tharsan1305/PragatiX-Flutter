class Team {
  final int id;
  final String name;
  final int size;
  final String? captainId;
  final String? captainName;
  final int? assignmentId;
  final String? activityName;
  final bool? isAwarded;
  final bool canDelete;
  final List<dynamic>? members; // Will refine based on StudentResponse if needed

  Team({
    required this.id,
    required this.name,
    required this.size,
    this.captainId,
    this.captainName,
    this.assignmentId,
    this.activityName,
    this.isAwarded,
    this.canDelete = false,
    this.members,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['teamId'] ?? json['id'],
      name: json['teamName'] ?? json['name'] ?? '',
      size: json['teamCapacity'] ?? json['size'] ?? 0,
      captainId: json['captainId'],
      captainName: json['captainName'],
      assignmentId: json['assignmentId'],
      activityName: json['assignmentName'] ?? json['activityName'],
      isAwarded: json['isAwarded'],
      canDelete: json['canDelete'] ?? false,
      members: json['teamMembers'] != null 
          ? List<dynamic>.from(json['teamMembers']) 
          : (json['members'] != null ? List<dynamic>.from(json['members']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'captainId': captainId,
      'captainName': captainName,
      'assignmentId': assignmentId,
      'activityName': activityName,
      'isAwarded': isAwarded,
      'members': members,
    };
  }
}
