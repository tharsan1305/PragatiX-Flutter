import '../models/activity_model.dart';
import '../models/my_activity_model.dart';
import '../services/activity_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity module – repository.
// Maps raw API data → domain models. UI never touches ActivityService directly.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityRepository {
  final ActivityService _service;

  ActivityRepository(ActivityService service) : _service = service;

  Future<List<MyActivityModel>> getMyActivities() async {
    final raw = await _service.fetchMyActivities();
    return raw
        .map((e) => MyActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityModel>> getActivities(int subgroupId) async {
    final raw = await _service.fetchActivities(subgroupId);
    return raw
        .map((e) => ActivityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> getDepartments() async {
    return _service.fetchDepartments();
  }

  Future<List<dynamic>> getTeachers() async {
    final users = await _service.fetchUsers();
    return users.where((u) {
      final roles = u['roles'] as List<dynamic>? ?? [];
      return roles.any((r) {
        if (r is String) return r == 'ROLE_TEACHER';
        if (r is Map) return r['name'] == 'ROLE_TEACHER';
        return false;
      });
    }).toList();
  }

  Future<ActivityModel> create(
      int subgroupId, Map<String, dynamic> body) async {
    final result = await _service.createActivity(subgroupId, body);
    final actData =
        result['data'] as Map<String, dynamic>? ?? result;
    return ActivityModel.fromJson(actData);
  }

  Future<ActivityModel> update(
      int activityId, Map<String, dynamic> body) async {
    final result = await _service.updateActivity(activityId, body);
    final actData =
        result['data'] as Map<String, dynamic>? ?? result;
    return ActivityModel.fromJson(actData);
  }

  Future<void> delete(int activityId) async {
    await _service.deleteActivity(activityId);
  }

  Future<List<dynamic>> getSections() async {
    return _service.fetchSections();
  }

  Future<Map<String, dynamic>> assign(
      int activityId, int? sectionId, int teacherId) async {
    return _service.assignActivity(activityId, sectionId, teacherId);
  }
}
