import 'package:flutter/foundation.dart';
import 'package:spdms_app/features/activity/models/activity_model.dart';
import 'package:spdms_app/features/activity/models/my_activity_model.dart';
import 'package:spdms_app/features/activity/repository/activity_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Activity module – state management (ChangeNotifier).
// The UI NEVER calls HTTP directly. Everything goes through this provider.
// ─────────────────────────────────────────────────────────────────────────────

class ActivityProvider extends ChangeNotifier {
  final ActivityRepository _repository;

  ActivityProvider(this._repository);

  String get token => _repository.token;

  // ── List state ────────────────────────────────────────────────────────────
  List<ActivityModel> activities = [];
  List<MyActivityModel> myActivities = [];
  List<dynamic> departments = [];
  List<dynamic> allTeachers = [];
  List<dynamic> sections = [];
  List<dynamic> classCoordinators = [];
  List<dynamic> customFrequencies = [];

  bool isLoadingActivities = false;
  bool isLoadingDependencies = false;
  bool isSaving = false;
  String? error;

  // ── Load my activities ────────────────────────────────────────────────────
  Future<void> loadMyActivities() async {
    isLoadingActivities = true;
    error = null;
    notifyListeners();
    try {
      myActivities = await _repository.getMyActivities();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      myActivities = [];
    } finally {
      isLoadingActivities = false;
      notifyListeners();
    }
  }

  // ── Load activities ───────────────────────────────────────────────────────
  Future<void> loadActivities({int? stageId, String? subgroupName}) async {
    isLoadingActivities = true;
    error = null;
    notifyListeners();
    try {
      activities = await _repository.getActivities(stageId: stageId, subgroupName: subgroupName);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      activities = [];
    } finally {
      isLoadingActivities = false;
      notifyListeners();
    }
  }

  // ── Load form dependencies (departments + teachers + sections) ───────────
  Future<void> loadDependencies() async {
    isLoadingDependencies = true;
    notifyListeners();
    try {
      departments = await _repository.getDepartments();
    } catch (_) {
      departments = [];
    }
    try {
      allTeachers = await _repository.getTeachers();
    } catch (_) {
      allTeachers = [];
    }
    try {
      sections = await _repository.getSections();
      debugPrint('DEBUG_LOG: Provider loaded sections count: ${sections.length}, data: $sections');
    } catch (e) {
      debugPrint('DEBUG_LOG: Provider failed to load sections: $e');
      sections = [];
    }
    try {
      classCoordinators = await _repository.getClassCoordinators();
      debugPrint('DEBUG_LOG: Provider loaded class coordinators count: ${classCoordinators.length}');
    } catch (e) {
      debugPrint('DEBUG_LOG: Provider failed to load class coordinators: $e');
      classCoordinators = [];
    }
    try {
      customFrequencies = await _repository.getCustomFrequencies();
    } catch (e) {
      customFrequencies = [];
    }
    isLoadingDependencies = false;
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<bool> createActivity(Map<String, dynamic> body, {int? stageId, String? subgroupName}) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final created = await _repository.create(body, stageId: stageId, subgroupName: subgroupName);
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

  Future<Map<String, dynamic>?> createCustomFrequency(Map<String, dynamic> body) async {
    error = null;
    notifyListeners();
    try {
      final newFreq = await _repository.createCustomFrequency(body);
      customFrequencies = [...customFrequencies, newFreq];
      notifyListeners();
      return newFreq;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
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
  Future<bool> mapExistingActivityToStage(int stageId, ActivityModel activity, String subgroupName) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.mapActivityToStage(stageId, activity.id, subgroupName);
      
      // Refresh list directly from backend to ensure all properties (like subgroup ids) are updated
      await loadActivities(stageId: stageId, subgroupName: subgroupName);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteActivity(int activityId, {bool force = false}) async {
    try {
      await _repository.delete(activityId, force: force);
      await loadActivities(); // Full refresh
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unmapActivityFromStage(int stageId, int activityId) async {
    try {
      await _repository.unmapActivityFromStage(stageId, activityId);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      await loadActivities(stageId: stageId); // Full refresh
    }
  }

  Future<List<dynamic>> getAssignments(int activityId) async {
    return await _repository.getAssignments(activityId);
  }

  Future<void> addAssignment(
      int activityId, int departmentId, String year, int? sectionId, int? teacherId, String scope) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.addAssignment(activityId, departmentId, year, sectionId, teacherId, scope);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> removeAssignment(int assignmentId) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.removeAssignment(assignmentId);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> clearAllAssignments(int activityId) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.clearAllAssignments(activityId);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> assignActivity(int activityId, bool ccEnabled, bool globalEnabled) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.assignActivity(activityId, ccEnabled, globalEnabled);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
