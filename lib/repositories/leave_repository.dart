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

  // Fixed submit leave request method
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
    try {
      // Normalize dates to remove time component
      final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
      
      // Validate and recalculate total days to match database constraint
      double validatedTotalDays;
      
      if (isHalfDay) {
        // Half day requests should have same start and end date
        if (!normalizedStart.isAtSameMomentAs(normalizedEnd)) {
          throw Exception('Half-day requests must have the same start and end date');
        }
        validatedTotalDays = 0.5;
      } else {
        // Calculate total days including both start and end date
        final daysDifference = normalizedEnd.difference(normalizedStart).inDays;
        validatedTotalDays = (daysDifference + 1).toDouble();
      }
      
      // Ensure the calculated days match what was passed
      if ((validatedTotalDays - totalDays).abs() > 0.01) {
        print('=== Days Mismatch ===');
        print('Passed total days: $totalDays');
        print('Calculated total days: $validatedTotalDays');
        print('Using calculated value: $validatedTotalDays');
      }

      // Prepare the data to insert
      final requestData = <String, dynamic>{
        'user_id': userId,
        'leave_type_id': leaveTypeId,
        'start_date': normalizedStart.toIso8601String().split('T')[0],
        'end_date': normalizedEnd.toIso8601String().split('T')[0],
        'total_days': validatedTotalDays, // Use the validated calculation
        'reason': reason.trim(),
        'is_half_day': isHalfDay,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add optional fields only if they have values
      if (halfDayPeriod != null && halfDayPeriod.isNotEmpty) {
        requestData['half_day_period'] = halfDayPeriod;
      }
      
      if (managerId != null && managerId.isNotEmpty) {
        requestData['manager_id'] = managerId;
      }

      print('=== Repository: Inserting data ===');
      print('Data to insert: $requestData');

      // First, insert the basic record without complex joins
      final insertResponse = await _client
          .from('leave_requests')
          .insert(requestData)
          .select()
          .single();

      print('=== Insert successful ===');
      print('Inserted record: $insertResponse');

      // Then fetch the complete record with relationships
      final completeResponse = await _client
          .from('leave_requests')
          .select('''
            *,
            leave_types(*),
            profiles!leave_requests_manager_id_fkey(*)
          ''')
          .eq('id', insertResponse['id'])
          .single();

      print('=== Complete record fetched ===');
      return LeaveRequest.fromJson(completeResponse);
      
    } catch (e) {
      print('=== Repository Error ===');
      print('Error type: ${e.runtimeType}');
      print('Error details: $e');
      
      if (e is PostgrestException) {
        print('Postgrest error code: ${e.code}');
        print('Postgrest error message: ${e.message}');
        print('Postgrest error details: ${e.details}');
        print('Postgrest error hint: ${e.hint}');
      }
      
      throw Exception('Failed to submit leave request: ${e.toString()}');
    }
  }

  // Get user's leave requests
  Future<List<LeaveRequest>> getUserLeaveRequests(String userId) async {
    try {
      final response = await _client
          .from('leave_requests')
          .select('''
            *,
            leave_types(*),
            profiles!leave_requests_manager_id_fkey(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LeaveRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching user requests: $e');
      rethrow;
    }
  }

  // Get team leave requests (for managers)
  Future<List<LeaveRequest>> getTeamLeaveRequests(String managerId) async {
    try {
      final response = await _client
          .from('leave_requests')
          .select('''
            *,
            leave_types(*),
            profiles!leave_requests_user_id_fkey(*)
          ''')
          .eq('manager_id', managerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LeaveRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching team requests: $e');
      rethrow;
    }
  }

  // Get pending requests for manager
  Future<List<LeaveRequest>> getPendingRequests(String managerId) async {
    try {
      final response = await _client
          .from('leave_requests')
          .select('''
            *,
            leave_types(*),
            profiles!leave_requests_user_id_fkey(*)
          ''')
          .eq('manager_id', managerId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LeaveRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching pending requests: $e');
      rethrow;
    }
  }

  // Update leave request status
  Future<LeaveRequest> updateLeaveRequestStatus(
    String requestId, 
    LeaveStatus status, 
    String? comments,
    String approverId,
  ) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.name,
        'approved_by': approverId,
        'approved_at': DateTime.now().toIso8601String(),
      };

      if (comments != null && comments.isNotEmpty) {
        updateData['manager_comments'] = comments;
      }

      final response = await _client
          .from('leave_requests')
          .update(updateData)
          .eq('id', requestId)
          .select('''
            *,
            leave_types(*),
            profiles!leave_requests_user_id_fkey(*)
          ''')
          .single();

      return LeaveRequest.fromJson(response);
    } catch (e) {
      print('Error updating request status: $e');
      rethrow;
    }
  }

  // Cancel leave request
  Future<LeaveRequest> cancelLeaveRequest(String requestId) async {
    try {
      final response = await _client
          .from('leave_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId)
          .select('''
            *,
            leave_types(*),
            profiles!leave_requests_manager_id_fkey(*)
          ''')
          .single();

      return LeaveRequest.fromJson(response);
    } catch (e) {
      print('Error cancelling request: $e');
      rethrow;
    }
  }

  // Get leave requests by date range
  Future<List<LeaveRequest>> getLeaveRequestsByDateRange(
    DateTime startDate, 
    DateTime endDate,
    {String? userId}
  ) async {
    try {
      var query = _client
          .from('leave_requests')
          .select('''
            *,
            leave_types(*),
            profiles!leave_requests_user_id_fkey(*)
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
    } catch (e) {
      print('Error fetching requests by date range: $e');
      rethrow;
    }
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