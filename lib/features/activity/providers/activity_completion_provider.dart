import 'package:flutter/material.dart';
import 'package:pragatix/features/activity/models/activity_completion_request.dart';
import 'package:pragatix/features/activity/services/activity_completion_service.dart';

class ActivityCompletionProvider with ChangeNotifier {
  final ActivityCompletionService _service;

  ActivityCompletionProvider(this._service);

  List<ActivityCompletionRequest> _myRequests = [];
  List<ActivityCompletionRequest> _inbox = [];
  bool _isLoading = false;
  String? _error;

  List<ActivityCompletionRequest> get myRequests => _myRequests;
  List<ActivityCompletionRequest> get inbox => _inbox;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyRequests() async {
    _setLoading(true);
    try {
      final response = await _service.getMyRequests();
      final List<dynamic> data = response['data'] ?? [];
      _myRequests = data
          .map((json) => ActivityCompletionRequest.fromJson(json))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadInbox() async {
    _setLoading(true);
    try {
      final response = await _service.getInbox();
      final List<dynamic> data = response['data'] ?? [];
      _inbox = data
          .map((json) => ActivityCompletionRequest.fromJson(json))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitRequest(
    int activityId, {
    int? teamId,
    String? proofUrl,
    String? reason,
  }) async {
    _setLoading(true);
    try {
      await _service.submitRequest(
        activityId,
        teamId: teamId,
        proofUrl: proofUrl,
        reason: reason,
      );
      await loadMyRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> approveRequest(int id) async {
    _setLoading(true);
    try {
      await _service.approveRequest(id);
      await loadInbox();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> rejectRequest(int id, String reason) async {
    _setLoading(true);
    try {
      await _service.rejectRequest(id, reason);
      await loadInbox();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  ActivityCompletionRequest? getMyRequestForActivity(
    int activityId, {
    int? teamId,
  }) {
    try {
      if (teamId != null) {
        return _myRequests.firstWhere(
          (r) => r.activityId == activityId && r.teamId == teamId,
        );
      } else {
        return _myRequests.firstWhere(
          (r) => r.activityId == activityId && r.teamId == null,
        );
      }
    } catch (e) {
      return null;
    }
  }
}
