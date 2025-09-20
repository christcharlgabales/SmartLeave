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
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Updated to match repository method signature
  Future<bool> submitLeaveRequest({
    required String userId,
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalDays,
    required String reason,
    bool isHalfDay = false,
    String? halfDayPeriod,
    String? managerId,
  }) async {
    _setLoading(true);
    try {
      final newRequest = await _leaveRepository.submitLeaveRequest(
        userId: userId,
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        totalDays: totalDays,
        reason: reason,
        isHalfDay: isHalfDay,
        halfDayPeriod: halfDayPeriod,
        managerId: managerId,
      );
      
      _userRequests.insert(0, newRequest);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
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
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
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
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Updated to pass approver ID
  Future<bool> updateRequestStatus(
    String requestId, 
    LeaveStatus status, 
    String? comments,
    String approverId, // Add this parameter
  ) async {
    _setLoading(true);
    try {
      final updatedRequest = await _leaveRepository.updateLeaveRequestStatus(
        requestId, 
        status, 
        comments,
        approverId, // Pass the approver ID
      );
      
      // Update local lists
      _updateLocalRequest(updatedRequest);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
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
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get leave requests for calendar view
  Future<List<LeaveRequest>> getLeaveRequestsByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {String? userId}
  ) async {
    try {
      return await _leaveRepository.getLeaveRequestsByDateRange(
        startDate, 
        endDate, 
        userId: userId,
      );
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      notifyListeners();
      return [];
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

  // Helper method to extract user-friendly error messages
  String _extractErrorMessage(String error) {
    if (error.contains('duplicate key value')) {
      return 'A leave request already exists for these dates.';
    }
    if (error.contains('violates foreign key constraint')) {
      return 'Invalid leave type or user information.';
    }
    if (error.contains('permission denied')) {
      return 'You do not have permission to perform this action.';
    }
    if (error.contains('invalid input syntax')) {
      return 'Invalid date format. Please check your dates.';
    }
    return 'Something went wrong. Please try again.';
  }

  // Convenience getters for filtered requests
  List<LeaveRequest> get approvedRequests =>
      _userRequests.where((r) => r.status == LeaveStatus.approved).toList();
  
  List<LeaveRequest> get rejectedRequests =>
      _userRequests.where((r) => r.status == LeaveStatus.rejected).toList();
  
  List<LeaveRequest> get cancelledRequests =>
      _userRequests.where((r) => r.status == LeaveStatus.cancelled).toList();
}