import 'package:flutter/material.dart';
import 'package:spdms_app/features/badge/repository/badge_repository.dart';

class BadgeProvider extends ChangeNotifier {
  final BadgeRepository _repository = BadgeRepository();

  List<dynamic> _earnedBadges = [];
  List<dynamic> _pendingBadges = [];
  List<dynamic> _availableBadges = [];
  List<dynamic> _teacherPendingClaims = [];
  
  bool _isLoading = false;

  List<dynamic> get earnedBadges => _earnedBadges;
  List<dynamic> get pendingBadges => _pendingBadges;
  List<dynamic> get availableBadges => _availableBadges;
  List<dynamic> get teacherPendingClaims => _teacherPendingClaims;
  bool get isLoading => _isLoading;

  Future<void> fetchMyBadges(String token) async {
    _isLoading = true;
    notifyListeners();
    
    final response = await _repository.fetchMyBadges(token);
    if (response['success'] == true) {
      final List<dynamic> list = response['data'];
      _earnedBadges = list.where((b) => b['status'] == 'APPROVED').toList();
      _pendingBadges = list.where((b) => b['status'] == 'PENDING').toList();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllBadges(String token) async {
    final response = await _repository.fetchAllBadges(token);
    if (response['success'] == true) {
      _availableBadges = response['data'];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitBadgeClaim(String token, String badgeName, String evidenceUrl) async {
    debugPrint('BadgeProvider: Calling repository submitBadgeClaim...');
    final response = await _repository.submitBadgeClaim(token, badgeName, evidenceUrl);
    debugPrint('BadgeProvider: Response received: $response');
    if (response['success'] == true) {
      debugPrint('BadgeProvider: Submission successful. Refreshing my badges...');
      await fetchMyBadges(token);
    }
    return response;
  }

  Future<void> fetchTeacherPendingClaims(String token) async {
    _isLoading = true;
    notifyListeners();
    
    final response = await _repository.fetchTeacherPendingClaims(token);
    if (response['success'] == true) {
      _teacherPendingClaims = response['data'];
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> approveClaim(String token, int claimId) async {
    final response = await _repository.approveClaim(token, claimId);
    if (response['success'] == true) {
      _teacherPendingClaims.removeWhere((c) => c['id'] == claimId);
      notifyListeners();
    }
    return response;
  }

  Future<Map<String, dynamic>> rejectClaim(String token, int claimId) async {
    final response = await _repository.rejectClaim(token, claimId);
    if (response['success'] == true) {
      _teacherPendingClaims.removeWhere((c) => c['id'] == claimId);
      notifyListeners();
    }
    return response;
  }
}
