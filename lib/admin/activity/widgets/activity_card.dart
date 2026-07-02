import 'package:flutter/material.dart';
import '../models/activity_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Material 3 activity card — used in the activity list.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const Color _dark = Color(0xFF1E293B);

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 14),
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
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.blue, size: 20),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
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
                _Tag('XP: ${activity.xp}', Colors.green),
                _Tag('Cap: ${activity.cap}', Colors.teal),
                _Tag('Freq: ${activity.frequency}',
                    Colors.amber.shade800),
                _Tag('Type: ${activity.type}', Colors.purple),
              ],
            ),

            const SizedBox(height: 10),

            // ── Owner row ──
            Row(
              children: [
                const Icon(Icons.assignment_ind_outlined,
                    size: 15, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Owner: ${activity.ownerDepartment} '
                    '(${activity.ownerSubrole.isNotEmpty ? activity.ownerSubrole : "All Teachers"})',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500),
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
