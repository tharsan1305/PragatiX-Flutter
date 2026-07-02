import '../models/activity_model.dart';
import '../services/activity_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity module – repository.
// Maps raw API data → domain models. UI never touches ActivityService directly.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityRepository {
  final ActivityService _service;

  ActivityRepository(ActivityService service) : _service = service;

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
      return roles.contains('ROLE_TEACHER');
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
}
