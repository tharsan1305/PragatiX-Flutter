import 'package:spdms_app/core/config/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spdms_app/screens/teacher/tabs/badge_claims_tab.dart';

class RemovalRequestsTab extends StatefulWidget {
  final String token;
  const RemovalRequestsTab({super.key, required this.token});

  @override
  State<RemovalRequestsTab> createState() => _RemovalRequestsTabState();
}

class _RemovalRequestsTabState extends State<RemovalRequestsTab> {
  // Dynamic data representing pending group removal requests
  List<dynamic> pendingRemovalRequests = [];
  bool _isRemovalsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRemovalRequests();
  }

  Future<void> _fetchRemovalRequests() async {
    setState(() => _isRemovalsLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/teams/removal-requests/pending"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          pendingRemovalRequests = data["data"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching removal requests: $e");
    } finally {
      setState(() => _isRemovalsLoading = false);
    }
  }

  Future<void> _handleRemovalRequest(int id, bool approve) async {
    try {
      final endpoint = approve ? "approve" : "reject";
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/teams/removal-requests/$id/$endpoint"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${approve ? "approved" : "rejected"} successfully'),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
        );
        _fetchRemovalRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? 'Failed to update request'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Approvals & Requests',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFF11998e),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.military_tech_rounded), text: "Badge Claims"),
              Tab(icon: Icon(Icons.group_remove_rounded), text: "Group Removals"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            BadgeClaimsTab(token: widget.token),
            _buildGroupRemovalsTab(),
          ],
        ),
      ),
    );
  }

  // ── TAB 2: GROUP REMOVALS ────────────────────────────────────────
  Widget _buildGroupRemovalsTab() {
    if (_isRemovalsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pendingRemovalRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No pending group removal requests!",
              style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingRemovalRequests.length,
      itemBuilder: (context, index) {
        final request = pendingRemovalRequests[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
            title: Text("Remove ${request['studentName']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text("From: ${request['teamName']}\nRequested by: ${request['captainName']}\nReason: ${request['reason']}", style: TextStyle(color: Colors.grey.shade700)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  onPressed: () => _handleRemovalRequest(request['id'], true),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                  onPressed: () => _handleRemovalRequest(request['id'], false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
