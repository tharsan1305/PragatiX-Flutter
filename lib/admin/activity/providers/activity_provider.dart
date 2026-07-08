import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import '../repository/activity_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity module – state management (ChangeNotifier).
// The UI NEVER calls HTTP directly. Everything goes through this provider.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityProvider extends ChangeNotifier {
  final ActivityRepository _repository;

  ActivityProvider(this._repository);

  // ── List state ────────────────────────────────────────────────────────────
  List<ActivityModel> activities = [];
  List<dynamic> departments = [];
  List<dynamic> allTeachers = [];

  bool isLoadingActivities = false;
  bool isLoadingDependencies = false;
  bool isSaving = false;
  String? error;

  // ── Load activities ───────────────────────────────────────────────────────
  Future<void> loadActivities(int subgroupId) async {
    isLoadingActivities = true;
    error = null;
    notifyListeners();
    try {
      activities = await _repository.getActivities(subgroupId);
    } catch (e) {
      error = e.toString();
      activities = [];
    } finally {
      isLoadingActivities = false;
      notifyListeners();
    }
  }

  // ── Load form dependencies (departments + teachers) ───────────────────────
  Future<void> loadDependencies() async {
    isLoadingDependencies = true;
    notifyListeners();
    try {
      departments = await _repository.getDepartments();
      allTeachers = await _repository.getTeachers();
    } catch (_) {
      departments = [];
      allTeachers = [];
    } finally {
      isLoadingDependencies = false;
      notifyListeners();
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<bool> createActivity(
      int subgroupId, Map<String, dynamic> body) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final created = await _repository.create(subgroupId, body);
      activities = [...activities, created];
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateActivity(
      int activityId, Map<String, dynamic> body) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final updated = await _repository.update(activityId, body);
      activities = activities
          .map((a) => a.id == activityId ? updated : a)
          .toList();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivity(int activityId) async {
    try {
      await _repository.delete(activityId);
    } catch (_) {
      // Optimistic removal even if API fails
    } finally {
      activities = activities.where((a) => a.id != activityId).toList();
      notifyListeners();
    }
  }
}
