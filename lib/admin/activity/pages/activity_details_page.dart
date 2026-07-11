import 'package:flutter/material.dart';
import '../models/activity_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity Details Page – read-only view of a single activity.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityDetailsPage extends StatelessWidget {
  final ActivityModel activity;

  static const Color _dark = Color(0xFF1E293B);

  const ActivityDetailsPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          activity.name,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailCard(
            icon: Icons.info_outline_rounded,
            title: 'Description',
            content: activity.description.isNotEmpty
                ? activity.description
                : 'No description',
          ),
          _DetailCard(
            icon: Icons.category_rounded,
            title: 'XP Category',
            content: activity.xpCategory.isNotEmpty
                ? activity.xpCategory
                : 'Academic',
          ),
          _DetailCard(
            icon: Icons.schedule_rounded,
            title: 'Frequency',
            content: activity.frequency.isNotEmpty
                ? activity.frequency
                : 'Not specified',
          ),
          _DetailCard(
            icon: Icons.person_outline_rounded,
            title: 'Assigned Faculty',
            content: activity.ownerSubrole.isNotEmpty
                ? activity.ownerSubrole
                : 'All Teachers',
          ),
          _DetailCard(
            icon: Icons.fact_check_outlined,
            title: 'Evidence',
            content: activity.evidence.isNotEmpty
                ? activity.evidence.join(', ')
                : 'Not specified',
          ),
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  icon: Icons.star_rounded,
                  title: 'XP',
                  content: activity.xp.isNotEmpty ? activity.xp : '—',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  icon: Icons.lock_clock_rounded,
                  title: 'Cap',
                  content: activity.cap > 0 ? activity.cap.toString() : '—',
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          _DetailCard(
            icon: Icons.people_rounded,
            title: 'Activity Type',
            content: activity.type.isNotEmpty ? activity.type : 'Individual',
          ),
          _DetailCard(
            icon: Icons.edit_note_rounded,
            title: 'Justification',
            content: activity.justification.isNotEmpty
                ? activity.justification
                : 'No justification provided',
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color? color;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  const _DetailCard({
    required this.icon,
    required this.title,
    required this.content,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? _primary;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                        fontSize: 14,
                        color: _dark,
                        fontWeight: FontWeight.w500),
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
