// lib/repositories/leave_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/leave_request.dart';
import '../models/leave_type.dart';

class LeaveRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get all leave types
  Future<List<LeaveType>> getLeaveTypes() async {
    final response = await _client
        .from('leave_types')
        .select()
        .eq('is_active', true)
        .order('name');

    return (response as List)
        .map((json) => LeaveType.fromJson(json))
        .toList();
  }

  // Submit leave request - now takes individual parameters instead of LeaveRequest object
  Future<LeaveRequest> submitLeaveRequest({
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
    final requestData = {
      'user_id': userId,
      'leave_type_id': leaveTypeId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'total_days': totalDays,
      'reason': reason,
      'is_half_day': isHalfDay,
      'half_day_period': halfDayPeriod,
      'manager_id': managerId,
      'status': 'pending',
    };

    final response = await _client
        .from('leave_requests')
        .insert(requestData)
        .select('''
          *,
          leave_types(*),
          manager:profiles!manager_id(*)
        ''')
        .single();

    return LeaveRequest.fromJson(response);
  }

  // Get user's leave requests
  Future<List<LeaveRequest>> getUserLeaveRequests(String userId) async {
    final response = await _client
        .from('leave_requests')
        .select('''
          *,
          leave_types(*),
          manager:profiles!manager_id(*)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => LeaveRequest.fromJson(json))
        .toList();
  }

  // Get team leave requests (for managers)
  Future<List<LeaveRequest>> getTeamLeaveRequests(String managerId) async {
    final response = await _client
        .from('leave_requests')
        .select('''
          *,
          leave_types(*),
          user:profiles!user_id(*)
        ''')
        .eq('manager_id', managerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => LeaveRequest.fromJson(json))
        .toList();
  }

  // Get pending requests for manager
  Future<List<LeaveRequest>> getPendingRequests(String managerId) async {
    final response = await _client
        .from('leave_requests')
        .select('''
          *,
          leave_types(*),
          user:profiles!user_id(*)
        ''')
        .eq('manager_id', managerId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => LeaveRequest.fromJson(json))
        .toList();
  }

  // Approve/Reject leave request - now takes approver ID as parameter
  Future<LeaveRequest> updateLeaveRequestStatus(
    String requestId, 
    LeaveStatus status, 
    String? comments,
    String approverId, // Add this parameter
  ) async {
    final updateData = {
      'status': status.name,
      'approved_by': approverId,
      'approved_at': DateTime.now().toIso8601String(),
      'manager_comments': comments,
    };

    final response = await _client
        .from('leave_requests')
        .update(updateData)
        .eq('id', requestId)
        .select('''
          *,
          leave_types(*),
          user:profiles!user_id(*)
        ''')
        .single();

    return LeaveRequest.fromJson(response);
  }

  // Cancel leave request (by user)
  Future<LeaveRequest> cancelLeaveRequest(String requestId) async {
    final response = await _client
        .from('leave_requests')
        .update({'status': 'cancelled'})
        .eq('id', requestId)
        .select('''
          *,
          leave_types(*),
          manager:profiles!manager_id(*)
        ''')
        .single();

    return LeaveRequest.fromJson(response);
  }

  // Get leave requests by date range
  Future<List<LeaveRequest>> getLeaveRequestsByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {String? userId}
  ) async {
    var query = _client
        .from('leave_requests')
        .select('''
          *,
          leave_types(*),
          user:profiles!user_id(*)
        ''')
        .gte('start_date', startDate.toIso8601String().split('T')[0])
        .lte('end_date', endDate.toIso8601String().split('T')[0])
        .eq('status', 'approved');

    if (userId != null) {
      query = query.eq('user_id', userId);
    }

    final response = await query.order('start_date');

    return (response as List)
        .map((json) => LeaveRequest.fromJson(json))
        .toList();
  }

  // Real-time subscription for leave requests
  RealtimeChannel subscribeToLeaveRequests({
    String? userId,
    String? managerId,
    required void Function(List<LeaveRequest>) onData,
  }) {
    var channel = _client.channel('leave_requests_${DateTime.now().millisecondsSinceEpoch}');
    
    if (userId != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'leave_requests',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => _refreshAndNotify(userId: userId, onData: onData),
      );
    }
    
    if (managerId != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'leave_requests',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'manager_id',
          value: managerId,
        ),
        callback: (_) => _refreshAndNotify(managerId: managerId, onData: onData),
      );
    }
    
    channel.subscribe();
    return channel;
  }

  Future<void> _refreshAndNotify({
    String? userId,
    String? managerId,
    required void Function(List<LeaveRequest>) onData,
  }) async {
    try {
      List<LeaveRequest> requests;
      if (userId != null) {
        requests = await getUserLeaveRequests(userId);
      } else if (managerId != null) {
        requests = await getTeamLeaveRequests(managerId);
      } else {
        requests = [];
      }
      onData(requests);
    } catch (e) {
      print('Error refreshing leave requests: $e');
    }
  }
}