import 'package:flutter/material.dart';

class PointReviewTab extends StatefulWidget {
  final String token;
  const PointReviewTab({super.key, required this.token});

  @override
  State<PointReviewTab> createState() => _PointReviewTabState();
}

class _PointReviewTabState extends State<PointReviewTab> {
  bool isLoading = false;
  List<dynamic> logs = [
    {
      "points": -10,
      "reason": "Late entry to class (repeated infraction)",
      "date": "2026-07-01",
      "category": "Attendance"
    },
    {
      "points": 20,
      "reason": "Active participation in college symposium presentation",
      "date": "2026-06-28",
      "category": "Academics"
    },
    {
      "points": -5,
      "reason": "Dress code minor infraction",
      "date": "2026-06-25",
      "category": "Discipline"
    },
    {
      "points": 10,
      "reason": "Volunteered in Blood Donation Camp",
      "date": "2026-06-20",
      "category": "Social Activity"
    },
    {
      "points": -5,
      "reason": "Using mobile phone in class hours",
      "date": "2026-06-15",
      "category": "Discipline"
    }
  ];

  int totalDeductions = 20;
  int totalRewards = 30;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    // In live backend phase, search or log fetch by username/profile would occur here.
    // For now, we utilize the mock dataset to ensure correct frontend rendering.
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Point Review",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Review Summary Banner
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade500.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade600.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle, color: Colors.green, size: 24),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Rewards", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text("+$totalRewards pts", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade600.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_circle, color: Colors.red, size: 24),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Deductions", style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Text("-$totalDeductions pts", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: logs.isEmpty
                ? const Center(child: Text("No discipline points modifications recorded."))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final points = log["points"] as int;
                      final isPositive = points > 0;
                      final category = log["category"] ?? "General";

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPositive ? Icons.check_circle_rounded : Icons.warning_rounded,
                                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Log details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            category.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          log["date"],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      log["reason"],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Points Indicator
                              Text(
                                isPositive ? "+$points" : "$points",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
