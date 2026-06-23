import 'package:flutter/material.dart';

class TeacherStudentDetail extends StatefulWidget {
  final Map<String, dynamic> student;

  const TeacherStudentDetail({super.key, required this.student});

  @override
  State<TeacherStudentDetail> createState() => _TeacherStudentDetailState();
}

class _TeacherStudentDetailState extends State<TeacherStudentDetail> {
  int currentScore = 0;

  @override
  void initState() {
    super.initState();
    currentScore = widget.student['score'] ?? 0;
  }

  void _changeScore(int points, String reason) {
    setState(() {
      currentScore += points;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${points > 0 ? "Added" : "Deducted"} $points points - $reason',
        ),
        backgroundColor: points > 0 ? Colors.green : Colors.red,
      ),
    );
  }

  void _showAddPointsSheet() {
    _showPointsBottomSheet(true);
  }

  void _showDeductPointsSheet() {
    _showPointsBottomSheet(false);
  }

  void _showPointsBottomSheet(bool isAdding) {
    final reasons = isAdding
        ? [
            "Attendance Above 95% (+10)",
            "Placement Training (+15)",
            "Internship Completion (+20)",
            "Hackathon Winner (+25)",
            "Academic Topper (+30)",
            "Faculty Appreciation (+10)"
          ]
        : [
            "Late Arrival (-3)",
            "Missing ID Card (-2)",
            "Mobile Usage (-5)",
            "Misbehavior (-10)",
            "Proxy Attendance (-15)",
            "Ragging (-50)",
            "Severe Misconduct (-100)"
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdding ? "Add Points" : "Deduct Points",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...reasons.map((reason) {
                return ListTile(
                  title: Text(reason),
                  onTap: () {
                    final points = int.parse(
                      reason.split(RegExp(r'[()]'))[1].replaceAll('+', '').replaceAll('-', '').trim(),
                    ) * (isAdding ? 1 : -1);
                    _changeScore(points, reason);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Card (Same style as your friend's)
            Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 60),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.student['name'],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text("Reg No: ${widget.student['regNo']}"),
                      Text("Department: ${widget.student['dept']}"),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Current Score
            Center(
              child: Column(
                children: [
                  const Text("Current Discipline Score", 
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    "$currentScore",
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
                  ),
                  const Text("Points", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddPointsSheet,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Points"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 207, 212, 207),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDeductPointsSheet,
                    icon: const Icon(Icons.remove),
                    label: const Text("Deduct Points"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 211, 206, 206),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text("Score History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Score history will appear here after connecting backend..."),
              ),
            ),
          ],
        ),
      ),
    );
  }
}