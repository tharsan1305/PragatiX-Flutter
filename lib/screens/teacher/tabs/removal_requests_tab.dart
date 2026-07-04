import 'package:flutter/material.dart';

class RemovalRequestsTab extends StatefulWidget {
  final String token;
  const RemovalRequestsTab({super.key, required this.token});

  @override
  State<RemovalRequestsTab> createState() => _RemovalRequestsTabState();
}

class _RemovalRequestsTabState extends State<RemovalRequestsTab> {
  // Dummy data representing pending removal requests
  final List<Map<String, String>> pendingRequests = [
    {"studentName": "David Smith", "groupName": "Science Club", "reason": "Not active"},
    {"studentName": "Emma Watson", "groupName": "Robotics Squad", "reason": "Switched classes"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Removal Requests'),
        backgroundColor: Colors.indigo,
      ),
      body: pendingRequests.isEmpty
          ? const Center(child: Text("No pending removal requests!"))
          : ListView.builder(
              itemCount: pendingRequests.length,
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                    title: Text("Remove ${request['studentName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("From: ${request['groupName']}\nReason: ${request['reason']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () {
                            setState(() {
                              pendingRequests.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request Approved!')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              pendingRequests.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request Rejected!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
