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
      error = e.toString();
      myActivities = [];
    } finally {
      isLoadingActivities = false;
      notifyListeners();
    }
  }

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

  Future<bool> assignActivity(
      int activityId, int? sectionId, int teacherId) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.assign(activityId, sectionId, teacherId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> saveAssignments(
      int activityId, bool globalEnabled, List<Map<String, dynamic>> assignments, {bool ccEnabled = false}) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.saveAssignments(activityId, globalEnabled, assignments, ccEnabled: ccEnabled);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
