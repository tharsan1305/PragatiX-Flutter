import 'package:flutter/material.dart';
import 'package:spdms_app/features/activity/models/activity_model.dart';
import 'package:spdms_app/features/activity/providers/activity_provider.dart';
import 'package:spdms_app/shared/widgets/activity_card.dart';
import 'package:spdms_app/features/activity/pages/create_activity_page.dart';
import 'package:spdms_app/features/activity/pages/edit_activity_page.dart';
import 'package:spdms_app/features/activity/pages/activity_execution_page.dart';
import 'package:spdms_app/features/activity/pages/group_activity_year_page.dart';
import 'package:spdms_app/features/activity/pages/assign_staff_page.dart';
import 'package:spdms_app/features/activity/repository/activity_repository.dart';
import 'package:spdms_app/core/di/service_locator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity List Page – entry point from SubgroupDetailsPage.
// Creates its own ActivityProvider (self-contained module boundary).
// ─────────────────────────────────────────────────────────────────────────────

class ActivityListPage extends StatefulWidget {
  final int subgroupId;
  final int? stageId;
  final String subgroupName;
  final String subgroupCategory;
  final List<dynamic> teachersList;
  final bool isCc;
  final bool isMyActivitiesOnly;
  final bool showAppBar;
  final bool isAdmin;

  const ActivityListPage({
    super.key,
    required this.subgroupId,
    this.stageId,
    required this.subgroupName,
    required this.subgroupCategory,
    required this.teachersList,
    this.isCc = false,
    this.isMyActivitiesOnly = false,
    this.showAppBar = true,
    this.isAdmin = false,
  });

  @override
  State<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends State<ActivityListPage> {
  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  late final ActivityProvider _provider;

  String _getCleanName(String fullName) {
    final lower = fullName.toLowerCase();
    if (lower.endsWith(' (must)')) {
      return fullName.substring(0, fullName.length - 7);
    }
    if (lower.endsWith(' (individual)')) {
      return fullName.substring(0, fullName.length - 13);
    }
    if (lower.endsWith(' (group)')) {
      return fullName.substring(0, fullName.length - 8);
    }
    return fullName;
  }

  String get _categoryLabel {
    final cat = widget.subgroupCategory.toLowerCase();
    if (cat == 'must' || cat == 'group' || cat == 'individual') {
      return cat.toUpperCase();
    }
    final name = widget.subgroupName.toLowerCase();
    if (name.contains('must')) return 'MUST';
    if (name.contains('group')) return 'GROUP';
    return 'INDIVIDUAL';
  }

  @override
  void initState() {
    super.initState();
    _provider = getIt<ActivityProvider>();
    if (widget.isMyActivitiesOnly) {
      _provider.loadMyActivities();
    } else {
      _provider.loadActivities(stageId: widget.stageId);
    }
    _provider.loadDependencies();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  Future<void> _openCreate() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateActivityPage(
          provider: _provider,
          stageId: widget.stageId,
          subgroupId: widget.subgroupId,
          subgroupName: widget.subgroupName,
          isCc: widget.isCc,
        ),
      ),
    );
    if (mounted) {
      if (widget.isMyActivitiesOnly) {
        await _provider.loadMyActivities();
      } else {
        await _provider.loadActivities(stageId: widget.stageId);
      }
      if (widget.isAdmin && _provider.activities.isNotEmpty) {
        final newAct = _provider.activities.last;
        await _openAssign(newAct);
      }
    }
  }

  Future<void> _openAssign(ActivityModel activity) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignStaffPage(
          provider: _provider,
          activity: activity,
        ),
      ),
    );
    _provider.loadActivities(stageId: widget.stageId, subgroupName: widget.subgroupName);
  }

  Future<void> _openEdit(ActivityModel activity) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditActivityPage(
          provider: _provider,
          activity: activity,
          isCc: widget.isCc,
        ),
      ),
    );
    if (mounted) {
      if (widget.isMyActivitiesOnly) {
        await _provider.loadMyActivities();
      } else {
        await _provider.loadActivities(stageId: widget.stageId);
      }
    }
  }

  void _showAddActivityOptions() {
    if (widget.stageId == null) {
      _openCreate();
      return;
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: _primary),
              title: const Text('Create New Activity'),
              subtitle: const Text('Create a brand new activity for this stage'),
              onTap: () {
                Navigator.pop(ctx);
                _openCreate();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: _primary),
              title: const Text('Add Existing Activity'),
              subtitle: const Text('Select from activities already in the system'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddExisting();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAddExisting() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final allRaw = await getIt<ActivityRepository>().getActivities();
      if (!mounted) return;
      Navigator.pop(context); // close loading

      final existingIds = _provider.activities.map((a) => a.id).toSet();
      final available = allRaw.where((a) => !existingIds.contains(a.id)).toList();

      if (available.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available activities found.')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Activity'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: available.length,
              itemBuilder: (context, index) {
                final act = available[index];
                return ListTile(
                  title: Text(act.name),
                  subtitle: Text(act.description ?? ''),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final success = await _provider.mapExistingActivityToStage(
                      widget.stageId!,
                      act,
                      widget.subgroupName ?? 'MUST',
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Activity mapped successfully'), backgroundColor: Colors.green),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading activities: $e')),
      );
    }
  }

  void _confirmDelete(ActivityModel activity, {bool isGlobalDelete = false}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isGlobalDelete ? 'Delete from System' : 'Remove Activity',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content:
            Text(isGlobalDelete 
              ? "Are you sure you want to completely delete '${activity.name}' from the entire system? This is permanent."
              : "Are you sure you want to remove '${activity.name}' from this stage?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (!isGlobalDelete && widget.stageId != null) {
                try {
                  await _provider.unmapActivityFromStage(widget.stageId!, activity.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity removed from stage'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                _executeGlobalDelete(activity, force: false);
              }
            },
            child:
                Text(isGlobalDelete ? 'Delete Everywhere' : 'Remove from Stage', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeGlobalDelete(ActivityModel activity, {bool force = false}) async {
    try {
      await _provider.deleteActivity(activity.id, force: force);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted everywhere'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('409:')) {
        final msg = errorStr.split('409:').last;
        if (mounted) {
          _showDependencyDialog(activity, msg);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $errorStr')),
          );
        }
      }
    }
  }

  void _showDependencyDialog(ActivityModel activity, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot Delete Activity'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeGlobalDelete(activity, force: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Force Delete'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cleanTitle = _getCleanName(widget.subgroupName);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                '$cleanTitle – Activities',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: _dark,
              elevation: 0,
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
            )
          : null,
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddActivityOptions,
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Activity',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          if (_provider.isLoadingActivities) {
            return const Center(child: CircularProgressIndicator());
          }

          final baseList = widget.isMyActivitiesOnly 
              ? _provider.myActivities.map((e) => e.toActivityModel()).toList() 
              : _provider.activities.where((a) {
                  if (a.subgroup == null) return false;
                  final sub = a.subgroup!.toUpperCase();
                  if (_categoryLabel == 'MUST') return sub.contains('MUST') || sub == 'M';
                  if (_categoryLabel == 'GROUP') return sub.contains('GROUP') || sub == 'G';
                  if (_categoryLabel == 'INDIVIDUAL') return sub.contains('INDIVIDUAL') || sub == 'I';
                  return false;
                }).toList();
                
          final list = baseList;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(cleanTitle),
              ),
              if (_provider.error != null)
                SliverToBoxAdapter(
                  child: _buildError(),
                ),
              if (list.isEmpty && _provider.error == null)
                SliverFillRemaining(
                  child: _buildEmpty(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final act = list[i];
                        return ActivityCard(
                          activity: act,
                          onEdit: () => _openEdit(act),
                          onRemoveFromStage: () => _confirmDelete(act, isGlobalDelete: false),
                          onDelete: () => _confirmDelete(act, isGlobalDelete: true),
                          onAssign: widget.isAdmin ? () => _openAssign(act) : null,
                          isCc: widget.isCc,
                          isReadOnly: widget.isMyActivitiesOnly,
                          showGlobalActions: true,
                          onTap: widget.isAdmin
                              ? null
                              : (widget.isMyActivitiesOnly
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) {
                                            final bool isGroupActivity = act.type.toLowerCase().contains('group');
                                            if (isGroupActivity) {
                                              return GroupActivityYearPage(
                                                
                                                activityId: act.id,
                                              );
                                            } else {
                                              return ActivityExecutionPage(
                                                
                                                activityId: act.id,
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    }
                                  : null),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String cleanTitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: 1.5,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cleanTitle,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _dark),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _categoryLabel,
                      style: const TextStyle(
                          color: _primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ListenableBuilder(
                    listenable: _provider,
                    builder: (context, _) {
                      final count = widget.isMyActivitiesOnly
                          ? _provider.myActivities.length
                          : _provider.activities.length;
                      final label = widget.isMyActivitiesOnly
                          ? 'activities assigned'
                          : 'activities configured';
                      return Text(
                        '$count $label',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_activity_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            widget.isMyActivitiesOnly ? 'No activities assigned.' : 'No activities mapped to this stage',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isMyActivitiesOnly
                ? 'Check back later or contact your Coordinator.'
                : 'Tap the button below to add the first activity.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.red.shade50,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _provider.error ?? 'An error occurred',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (widget.isMyActivitiesOnly) {
                    _provider.loadMyActivities();
                  } else {
                    _provider.loadActivities(stageId: widget.stageId);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
