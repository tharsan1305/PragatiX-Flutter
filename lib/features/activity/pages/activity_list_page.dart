import 'package:flutter/material.dart';
import '../../../features/activity/models/activity_model.dart';
import '../../../features/activity/models/my_activity_model.dart';
import '../../../features/activity/providers/activity_provider.dart';
import '../../../features/activity/repository/activity_repository.dart';
import '../../../features/activity/services/activity_service.dart';
import '../../../features/activity/widgets/activity_card.dart';
import 'create_activity_page.dart';
import 'edit_activity_page.dart';
import 'activity_execution_page.dart';
import 'group_activity_year_page.dart';
import 'admin_activity_detail_page.dart';
import 'assign_faculty_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity List Page – entry point from SubgroupDetailsPage.
// Creates its own ActivityProvider (self-contained module boundary).
// ─────────────────────────────────────────────────────────────────────────────

class ActivityListPage extends StatefulWidget {
  final String token;
  final int subgroupId;
  final String subgroupName;
  final String subgroupCategory;
  final List<dynamic> teachersList;
  final bool isCc;
  final bool isMyActivitiesOnly;
  final bool showAppBar;
  final bool isAdmin;

  const ActivityListPage({
    super.key,
    required this.token,
    required this.subgroupId,
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
    _provider = ActivityProvider(
      ActivityRepository(ActivityService(widget.token)),
    );
    if (widget.isMyActivitiesOnly) {
      _provider.loadMyActivities();
    } else {
      _provider.loadActivities(widget.subgroupId);
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
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateActivityPage(
          provider: _provider,
          subgroupId: widget.subgroupId,
          isCc: widget.isCc,
        ),
      ),
    );
    if (saved == true && mounted) {
      if (widget.isMyActivitiesOnly) {
        await _provider.loadMyActivities();
      } else {
        await _provider.loadActivities(widget.subgroupId);
      }
      if (widget.isAdmin && _provider.activities.isNotEmpty) {
        final newAct = _provider.activities.last;
        await _openAssign(newAct);
      }
    }
  }

  Future<void> _openAssign(ActivityModel activity) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignFacultyPage(
          provider: _provider,
          activity: activity,
        ),
      ),
    );
    if (saved == true && mounted) {
      if (widget.isMyActivitiesOnly) {
        await _provider.loadMyActivities();
      } else {
        await _provider.loadActivities(widget.subgroupId);
      }
    }
  }

  Future<void> _openEdit(ActivityModel activity) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditActivityPage(
          provider: _provider,
          activity: activity,
          isCc: widget.isCc,
        ),
      ),
    );
    if (saved == true && mounted) {
      if (widget.isMyActivitiesOnly) {
        await _provider.loadMyActivities();
      } else {
        await _provider.loadActivities(widget.subgroupId);
      }
    }
  }

  void _confirmDelete(ActivityModel activity) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Activity',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            Text("Are you sure you want to delete '${activity.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _provider.deleteActivity(activity.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Activity deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
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
              onPressed: _openCreate,
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

          final list = widget.isMyActivitiesOnly
              ? _provider.myActivities.map((e) => e.toActivityModel()).toList()
              : _provider.activities;

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
                          onDelete: () => _confirmDelete(act),
                          onAssign: widget.isAdmin ? () => _openAssign(act) : null,
                          isCc: widget.isCc,
                          isReadOnly: widget.isMyActivitiesOnly,
                          onTap: widget.isAdmin
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminActivityDetailPage(
                                        token: widget.token,
                                        activity: act,
                                        subgroupId: widget.subgroupId,
                                      ),
                                    ),
                                  );
                                }
                              : (widget.isMyActivitiesOnly
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) {
                                            bool isGroupActivity = act.type.toLowerCase().contains('group');
                                            if (isGroupActivity) {
                                              return GroupActivityYearPage(
                                                token: widget.token,
                                                activityId: act.id,
                                              );
                                            } else {
                                              return ActivityExecutionPage(
                                                token: widget.token,
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
            widget.isMyActivitiesOnly ? 'No activities assigned.' : 'No activities yet',
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
                    _provider.loadActivities(widget.subgroupId);
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
