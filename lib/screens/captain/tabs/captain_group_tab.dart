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
  bool _isLoading = true;
  Map<String, dynamic>? _groupData;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _fetchMyGroup();
  }

  Future<void> _fetchMyGroup() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/v1/teams/my-team"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["success"] == true) {
          setState(() {
            _groupData = data["data"];
            _members = _groupData?["teamMembers"] ?? [];
          });
        } else {
          setState(() {
            _groupData = null;
            _members = [];
          });
        }
      } else {
        setState(() {
          _groupData = null;
          _members = [];
        });
      }
    } catch (e) {
      // Network error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCreateGroup(String name, int size, String membersStr) async {
    List<String> memberIds = membersStr.split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/teams"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "name": name,
          "size": size,
          "memberStudentIds": memberIds,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201 && data["success"] == true) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!'), backgroundColor: Colors.green),
        );
        _fetchMyGroup();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? 'Failed to create group'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _addMember(String studentId) async {
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/teams/my-team/add-member?studentId=$studentId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully!'), backgroundColor: Colors.green),
        );
        _fetchMyGroup();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? 'Failed to add member'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _removeMember(String studentId, String name) async {
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/api/v1/teams/my-team/remove-member?studentId=$studentId"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed $name successfully!'), backgroundColor: Colors.green),
        );
        _fetchMyGroup();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? 'Failed to remove member'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
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

  void _showAddMemberDialog() {
    final idCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Group Member"),
          content: TextField(
            controller: idCtrl,
            decoration: const InputDecoration(
              labelText: "Student Register ID",
              hintText: "e.g., R2402022",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (idCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Register ID is required!')),
                  );
                  return;
                }
                _addMember(idCtrl.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateLimitDialog() {
    final limitCtrl = TextEditingController(text: (_groupData?["teamCapacity"] ?? 10).toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Group Limit"),
          content: TextField(
            controller: limitCtrl,
            decoration: const InputDecoration(
              labelText: "Max Size Limit",
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSize = int.tryParse(limitCtrl.text);
                if (newSize == null || newSize <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive number')),
                  );
                  return;
                }
                Navigator.pop(context);
                await _updateGroupLimit(newSize);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGroupLimit(int newSize) async {
    try {
      final response = await http.put(
        Uri.parse("http://10.0.2.2:8080/api/v1/teams/my-team/limit?size=$newSize"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group limit updated successfully!'), backgroundColor: Colors.green),
        );
        _fetchMyGroup();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? 'Failed to update group limit'), backgroundColor: Colors.redAccent),
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
    final hasGroup = _groupData != null;
    final groupName = _groupData?["teamName"] ?? "My Group";
    final captainId = _groupData?["captainId"];
    final maxSize = _groupData?["teamCapacity"] ?? 10;
    final currentSize = _members.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hasGroup ? groupName : 'Group Setup'),
            if (hasGroup)
              Text(
                "Limit: $currentSize / $maxSize members",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.amber, // Captain Color
        actions: hasGroup ? [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showUpdateLimitDialog,
            tooltip: "Change Group Limit",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMyGroup,
          )
        ] : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasGroup
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_off_rounded, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "You don't have a group yet",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Create your group to get started. Once created, you will be designated as the Captain.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showCreateGroupDialog,
                          icon: const Icon(Icons.group_add_rounded),
                          label: const Text("Create Group Now"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group_rounded, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text("No members in this group yet"),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddMemberDialog,
                            icon: const Icon(Icons.person_add),
                            label: const Text("Add First Member"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final isCaptain = member["studentId"] == captainId;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCaptain ? Colors.amber : Colors.indigo,
                              child: Icon(
                                isCaptain ? Icons.star_rounded : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(member["fullName"] ?? "Student"),
                            subtitle: Text("Reg No: ${member["studentId"]}"),
                            trailing: isCaptain
                                ? const Chip(
                                    label: Text("Captain", style: TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.amber,
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                                    onPressed: () => _removeMember(member["studentId"], member["fullName"]),
                                  ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: hasGroup
          ? FloatingActionButton.extended(
              onPressed: _showAddMemberDialog,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text("Add Member"),
              backgroundColor: Colors.amber,
            )
          : null,
    );
  }
}
