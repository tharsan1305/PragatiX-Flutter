import 'package:flutter/material.dart';
import 'package:spdms_app/core/theme/app_colors.dart';
import 'package:spdms_app/features/activity/models/activity_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Material 3 activity card — used in the activity list.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAssign;
  final VoidCallback? onTap;
  final bool isCc;
  final bool isReadOnly;

  static const Color _dark = AppColors.darkSlate;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onEdit,
    required this.onDelete,
    this.onAssign,
    this.onTap,
    this.isCc = false,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    activity.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _dark,
                    ),
                  ),
                ),
                if (!isReadOnly) ...[
                  if (onAssign != null)
                    IconButton(
                      icon: const Icon(Icons.assignment_ind_outlined,
                          color: Colors.green, size: 20),
                      onPressed: onAssign,
                      tooltip: 'Assign Faculty',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  IconButton(
                    icon: Icon(
                        isCc ? Icons.assignment_ind_outlined : Icons.edit_outlined,
                        color: Colors.blue, size: 20),
                    onPressed: onEdit,
                    tooltip: isCc ? 'Assign Faculty/Owner' : 'Edit',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  if (!isCc)
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ],
            ),

            // ── Description ──
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                activity.description,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Tags ──
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (activity.awardEnabled)
                  _Tag('Award: ${activity.awardXp}', Colors.green),
                if (activity.penaltyEnabled)
                  _Tag('Penalty: ${activity.penaltyXp}', Colors.red),
                _Tag('Cap: ${activity.cap}', Colors.teal),
                _Tag('Freq: ${activity.awardFrequency}',
                    Colors.amber.shade800),
                _Tag('Type: ${activity.type}', Colors.purple),
              ],
            ),

            const SizedBox(height: 10),

            // ── Owner/Assignments row ──
            if (activity.assignmentSummary.isEmpty)
              Row(
                children: [
                  const Icon(Icons.assignment_ind_outlined,
                      size: 15, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Department: ${activity.ownerDepartment.isNotEmpty ? activity.ownerDepartment : "Unassigned"} (No assignments yet)',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_ind_outlined,
                          size: 15, color: Colors.blue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.assignmentMode == 'GLOBAL'
                              ? 'Assignment Mode: Global (All Departments)'
                              : 'Assignments (${activity.ownerDepartment}):',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 21),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: activity.assignmentSummary.map((assign) {
                        final secName = assign['section'] as String?;
                        final teachName = assign['teacher'] as String? ?? 'Unknown Teacher';
                        final text = secName != null
                            ? 'Section $secName → $teachName'
                            : 'Assigned to → $teachName';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• $text',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

            // ── Evidence ──
            if (activity.evidence.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.fact_check_outlined,
                      size: 15, color: Colors.indigo),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Evidence: ${activity.evidence.join(", ")}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ],

            // ── Justification ──
            if (activity.justification.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Justification: ${activity.justification}',
                style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
     ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
