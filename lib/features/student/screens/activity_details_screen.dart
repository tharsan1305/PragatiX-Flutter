import 'package:flutter/material.dart';

class ActivityDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailsScreen({Key? key, required this.activity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = activity['activityName'] ?? 'Activity Details';
    final String description = activity['description'] ?? 'No description provided.';
    final int rewardXp = activity['rewardXp'] ?? 0;
    final int awardedXp = activity['awardedXp'] ?? 0;
    final String status = activity['status'] ?? 'PENDING';
    final bool isCompleted = status == 'COMPLETED';
    
    final String facultyName = activity['facultyName'] ?? 'Unassigned';
    final String frequency = activity['frequency'] ?? 'N/A';
    
    // evidence could be a List or a String in some backend setups, assuming List
    final dynamic evidenceRaw = activity['evidence'];
    final List<String> evidence = evidenceRaw is List 
        ? evidenceRaw.map((e) => e.toString()).toList() 
        : (evidenceRaw != null ? [evidenceRaw.toString()] : []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Activity Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted ? Colors.green.shade300 : Colors.amber.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: isCompleted ? Colors.green.shade700 : Colors.amber.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green.shade700 : Colors.amber.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Name & Description
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            
            // Details Grid
            const Text(
              'Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            
            _InfoRow(
              icon: Icons.star_rounded,
              title: 'Reward',
              value: '$rewardXp XP',
              iconColor: Colors.amber,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.military_tech_rounded,
              title: 'Awarded',
              value: '$awardedXp XP',
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.person_rounded,
              title: 'Faculty / Owner',
              value: facultyName,
              iconColor: Colors.purple,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.repeat_rounded,
              title: 'Frequency',
              value: frequency,
              iconColor: Colors.teal,
            ),
            
            const SizedBox(height: 32),
            
            // Evidence Section
            if (evidence.isNotEmpty) ...[
              const Text(
                'Required Evidence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: evidence.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attachment, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        e,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
