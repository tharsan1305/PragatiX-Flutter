part of 'team_group_management_tab.dart';

extension TeamGroupManagementDialogs on _TeamGroupManagementTabState {
  void _showUpdateLimitDialog(int teamId, int currentSize) {
    final limitCtrl = TextEditingController(text: currentSize.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Group Limit'),
          content: TextField(
            controller: limitCtrl,
            decoration: const InputDecoration(
              labelText: 'Max Size Limit',
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
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
                await _updateGroupLimit(teamId, newSize);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGroupLimit(int teamId, int newSize) async {
    try {
      final response = await getIt<TeamProxyService>().put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/$teamId/limit?size=$newSize'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      final data = json.decode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group limit updated successfully!'), backgroundColor: Colors.green),
        );
        _fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update group limit'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showAddMemberDialog(int teamId) {
    final studentIdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Member'),
          content: TextField(
            controller: studentIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Student ID (e.g. 24CS01)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final regNo = studentIdCtrl.text.trim();
                if (regNo.isNotEmpty) {
                  Navigator.pop(context);
                  _addMemberByCC(teamId, regNo);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMemberByCC(int teamId, String regNo) async {
    try {
      final response = await getIt<TeamProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/$teamId/add-member?regNo=$regNo'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      final data = json.decode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully!'), backgroundColor: Colors.green),
        );
        _fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to add member'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: "5");
    Map<String, dynamic>? selectedCaptain;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Team'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Team Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: limitCtrl,
                      decoration: const InputDecoration(labelText: 'Max Size Limit', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    StudentSearchField(
                      selectedStudent: selectedCaptain,
                      onStudentSelected: (student) {
                        setState(() {
                          selectedCaptain = student;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final limit = int.tryParse(limitCtrl.text) ?? 5;
                    
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Team Name is required'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }
                    if (limit < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Team Capacity must be at least 1'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }
                    if (selectedCaptain == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Captain is required'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    _createGroup(name, limit, selectedCaptain!['regNo']);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createGroup(String name, int limit, String captainStudentId) async {
    try {
      final body = jsonEncode({
        'name': name,
        'size': limit,
        'captainStudentId': captainStudentId,
      });

      final response = await getIt<TeamProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final data = json.decode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team created successfully!'), backgroundColor: Colors.green),
          );
          _fetchGroups();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to create team'), backgroundColor: Colors.redAccent),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to create team'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showEditTeamDialog(Map<String, dynamic> team, int currentSize) {
    final nameCtrl = TextEditingController(text: team['teamName']);
    final limitCtrl = TextEditingController(text: currentSize.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Team Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitCtrl,
                decoration: const InputDecoration(labelText: 'Max Size Limit', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final limit = int.tryParse(limitCtrl.text);
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
                  return;
                }
                if (limit == null || limit <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid limit')));
                  return;
                }
                Navigator.pop(context);
                await _updateTeam(team['teamId'], name, limit);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateTeam(int teamId, String name, int limit) async {
    try {
      final body = jsonEncode({
        'name': name,
        'size': limit,
      });

      final response = await getIt<TeamProxyService>().put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/$teamId'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      final data = json.decode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team updated successfully!'), backgroundColor: Colors.green),
        );
        _fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update team'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showDeleteTeamDialog(int teamId, String teamName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Team'),
          content: Text('Are you sure you want to delete the team "$teamName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteTeam(teamId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTeam(int teamId) async {
    try {
      final response = await getIt<TeamProxyService>().delete(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/$teamId'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      final data = json.decode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team deleted successfully!'), backgroundColor: Colors.green),
        );
        _fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to delete team'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  void _showChangeCaptainDialog(Map<String, dynamic> team) {
    final members = team['teamMembers'] as List? ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No members in team to promote')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Captain'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (context, index) {
                final m = members[index];
                return ListTile(
                  title: Text(m['fullName'] ?? 'Student'),
                  subtitle: Text(m['regNo'] ?? ''),
                  onTap: () {
                    Navigator.pop(context);
                    _changeCaptain(team['teamId'], m['regNo']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  Future<void> _changeCaptain(int teamId, String regNo) async {
    try {
      final response = await getIt<TeamProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/teams/$teamId/captain?regNo=$regNo'),
        headers: {
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
      );

      final data = json.decode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Captain changed successfully!'), backgroundColor: Colors.green),
        );
        _fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to change captain'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.orange),
      );
    }
  }
}
