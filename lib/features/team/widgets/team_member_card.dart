import 'package:flutter/material.dart';

class TeamMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final String? captainId;
  final bool canManage;
  final bool isCaptainRoleSection;
  final VoidCallback? onRemove;
  final VoidCallback? onChangeCaptainRequest;

  const TeamMemberCard({
    super.key,
    required this.member,
    this.captainId,
    this.canManage = false,
    this.isCaptainRoleSection = false,
    this.onRemove,
    this.onChangeCaptainRequest,
  });

  String _getStageName(int level) {
    switch (level) {
      case 1: return 'Explorer';
      case 2: return 'Builder';
      case 3: return 'Innovator';
      case 4: return 'Specialist';
      case 5: return 'Leader';
      case 6: return 'Mentor';
      case 7: return 'Architect';
      case 8: return 'Industry Ready';
      default: return 'Explorer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCaptain = member['regNo'] == captainId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isCaptain ? Colors.amber.shade100 : Colors.indigo.shade50,
              child: Icon(
                isCaptain ? Icons.star_rounded : Icons.person,
                size: 20,
                color: isCaptain ? Colors.amber.shade800 : Colors.indigo.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          member['fullName'] ?? 'Student',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      if (isCaptain)
                        const Chip(
                          label: Text('CAPTAIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                          backgroundColor: Colors.amber,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      if (canManage && !isCaptainRoleSection)
                        if (!isCaptain)
                          IconButton(
                            icon: const Icon(Icons.person_remove, color: Colors.red, size: 18),
                            tooltip: 'Remove Member',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: onRemove,
                          )
                        else if (isCaptain && onChangeCaptainRequest != null)
                          IconButton(
                            icon: const Icon(Icons.person_remove, color: Colors.grey, size: 18),
                            tooltip: 'Change Captain First',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: onChangeCaptainRequest,
                          ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${member["regNo"] ?? ''} • ${member["department"] ?? ''} ${member["year"] ?? ''} ${member["section"] ?? ''}".trim(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text("${member["currentXp"] ?? 0} XP", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Stage : Level ${member['currentStage'] ?? 1} - ${_getStageName(member['currentStage'] ?? 1)}",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.indigo.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
