// lib/providers/leave_provider.dart
import 'package:flutter/material.dart';
import '../repositories/leave_repository.dart';
import '../models/leave_request.dart';
import '../models/leave_type.dart';

class LeaveProvider extends ChangeNotifier {
  final LeaveRepository _leaveRepository = LeaveRepository();
  
  List<LeaveRequest> _userRequests = [];
  List<LeaveRequest> _teamRequests = [];
  List<LeaveRequest> _pendingRequests = [];
  List<LeaveType> _leaveTypes = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  List<LeaveRequest> get userRequests => _userRequests;
  List<LeaveRequest> get teamRequests => _teamRequests;
  List<LeaveRequest> get pendingRequests => _pendingRequests;
  List<LeaveType> get leaveTypes => _leaveTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadLeaveTypes() async {
    try {
      _leaveTypes = await _leaveRepository.getLeaveTypes();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> submitLeaveRequest(LeaveRequest request) async {
    _setLoading(true);
    try {
      final newRequest = await _leaveRepository.submitLeaveRequest(request);
      _userRequests.insert(0, newRequest);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserRequests(String userId) async {
    _setLoading(true);
    try {
      _userRequests = await _leaveRepository.getUserLeaveRequests(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTeamRequests(String managerId) async {
    _setLoading(true);
    try {
      _teamRequests = await _leaveRepository.getTeamLeaveRequests(managerId);
      _pendingRequests = await _leaveRepository.getPendingRequests(managerId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRequestStatus(
    String requestId, 
    LeaveStatus status, 
    String? comments
  ) async {
    _setLoading(true);
    try {
      final updatedRequest = await _leaveRepository.updateLeaveRequestStatus(
        requestId, status, comments
      );
      
      // Update local lists
      _updateLocalRequest(updatedRequest);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    _setLoading(true);
    try {
      final updatedRequest = await _leaveRepository.cancelLeaveRequest(requestId);
      _updateLocalRequest(updatedRequest);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _updateLocalRequest(LeaveRequest updatedRequest) {
    // Update in user requests
    final userIndex = _userRequests.indexWhere((r) => r.id == updatedRequest.id);
    if (userIndex != -1) {
      _userRequests[userIndex] = updatedRequest;
    }

    // Update in team requests
    final teamIndex = _teamRequests.indexWhere((r) => r.id == updatedRequest.id);
    if (teamIndex != -1) {
      _teamRequests[teamIndex] = updatedRequest;
    }

    // Update pending requests
    if (updatedRequest.status != LeaveStatus.pending) {
      _pendingRequests.removeWhere((r) => r.id == updatedRequest.id);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}