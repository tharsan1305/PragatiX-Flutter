import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CaptainGroupTab extends StatefulWidget {
  final String token;
  const CaptainGroupTab({super.key, required this.token});

  @override
  State<CaptainGroupTab> createState() => _CaptainGroupTabState();
}

class _CaptainGroupTabState extends State<CaptainGroupTab> {
  // Dummy data representing the Captain's current members
  final List<String> groupMembers = ["Alice Johnson", "Bob Smith", "Charlie Brown"];

  Future<void> _submitCreateGroup(String name, int size, String membersStr) async {
    // Convert comma-separated string to list, ignoring empty strings
    List<String> memberIds = membersStr.split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/groups"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "name": name,
          "size": size,
          // We removed captainStudentId because the backend will use the logged-in Captain!
          "memberStudentIds": memberIds,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${json.decode(response.body)['message'] ?? response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final sizeCtrl = TextEditingController(text: "10");
    final membersCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create My Group"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Group Name"),
                ),
                TextField(
                  controller: sizeCtrl,
                  decoration: const InputDecoration(labelText: "Max Size"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: membersCtrl,
                  decoration: const InputDecoration(labelText: "Member IDs (comma separated)"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Group Name is required!')),
                  );
                  return;
                }
                _submitCreateGroup(
                  nameCtrl.text.trim(),
                  int.tryParse(sizeCtrl.text) ?? 10,
                  membersCtrl.text,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Group'),
        backgroundColor: Colors.amber, // Captain Color
      ),
      body: ListView.builder(
        itemCount: groupMembers.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(groupMembers[index]),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Requested removal for ${groupMembers[index]}')),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text("Create Group"),
        backgroundColor: Colors.amber,
      ),
    );
  }
}
