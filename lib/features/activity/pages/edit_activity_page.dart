import 'package:flutter/material.dart';
import 'package:spdms_app/features/activity/models/activity_model.dart';
import 'package:spdms_app/features/activity/providers/activity_provider.dart';
import 'package:spdms_app/features/activity/widgets/activity_form.dart';
import 'package:spdms_app/features/activity/widgets/sticky_bottom_buttons.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Edit Activity Page – reuses ActivityForm with pre-filled data.
// Shares the same form widget as CreateActivityPage (no code duplication).
// ─────────────────────────────────────────────────────────────────────────────

class EditActivityPage extends StatefulWidget {
  final ActivityProvider provider;
  final ActivityModel activity;
  final bool isCc;

  const EditActivityPage({
    super.key,
    required this.provider,
    required this.activity,
    this.isCc = false,
  });

  @override
  State<EditActivityPage> createState() => _EditActivityPageState();
}

class _EditActivityPageState extends State<EditActivityPage>
    with SingleTickerProviderStateMixin {
  static const Color _dark = Color(0xFF1E293B);

  final _formKey = GlobalKey<ActivityFormState>();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (widget.isCc) {
      final body = _formKey.currentState?.buildCcAssignmentBody();
      if (body == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a teacher (and section if applicable).'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final ok = await widget.provider.assignActivity(
        widget.activity.id,
        body['sectionId'] as int?,
        body['teacherId'] as int,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher assigned successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(widget.provider.error ?? 'Failed to assign teacher.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      final body = _formKey.currentState?.buildBody();
      if (body == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all required fields.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final ok =
          await widget.provider.updateActivity(widget.activity.id, body);

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(widget.provider.error ?? 'Failed to update activity.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 110,
              backgroundColor: _dark,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Edit Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _onSave,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
          body: ListenableBuilder(
            listenable: widget.provider,
            builder: (context, _) {
              if (widget.provider.isLoadingDependencies) {
                return const Center(child: CircularProgressIndicator());
              }
              return ActivityForm(
                key: _formKey,
                allTeachers: widget.provider.allTeachers,
                sections: widget.provider.sections,
                
                provider: widget.provider,
                initialData: widget.activity,
                isCc: widget.isCc,
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.provider,
        builder: (context, _) => StickyBottomButtons(
          saveLabel: 'Save Changes',
          onSave: _onSave,
          onCancel: () => Navigator.pop(context),
          isSaving: widget.provider.isSaving,
        ),
      ),
    );
  }
}
