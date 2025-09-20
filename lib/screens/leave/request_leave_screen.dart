// lib/screens/leave/request_leave_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../models/leave_request.dart';
import '../../models/leave_type.dart';

class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  LeaveType? _selectedLeaveType;
  bool _isHalfDay = false;
  double _calculatedDays = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().loadLeaveTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Leave'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Consumer2<AuthProvider, LeaveProvider>(
        builder: (context, authProvider, leaveProvider, child) {
          if (leaveProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Leave Type Selection
                  _buildLeaveTypeSection(leaveProvider),
                  const SizedBox(height: 24),

                  // Date Selection
                  _buildDateSection(),
                  const SizedBox(height: 24),

                  // Half Day Option
                  _buildHalfDaySection(),
                  const SizedBox(height: 24),

                  // Days Calculation Display
                  _buildDaysCalculation(),
                  const SizedBox(height: 24),

                  // Leave Balance Check
                  if (_selectedLeaveType != null)
                    _buildLeaveBalanceCheck(authProvider.currentUser!),
                  const SizedBox(height: 24),

                  // Reason
                  _buildReasonSection(),
                  const SizedBox(height: 32),

                  // Submit Button
                  _buildSubmitButton(authProvider, leaveProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaveTypeSection(LeaveProvider leaveProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderDropdown<LeaveType>(
          name: 'leaveType',
          decoration: const InputDecoration(
            labelText: 'Select leave type',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: leaveProvider.leaveTypes
              .map((leaveType) => DropdownMenuItem(
                    value: leaveType,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(int.parse(
                                leaveType.color.replaceFirst('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(leaveType.name),
                              if (leaveType.description != null)
                                Text(
                                  leaveType.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          validator: FormBuilderValidators.required(),
          onChanged: (leaveType) {
            setState(() {
              _selectedLeaveType = leaveType;
            });
            _calculateDays();
          },
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dates',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FormBuilderDateTimePicker(
                name: 'startDate',
                inputType: InputType.date,
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                validator: FormBuilderValidators.required(),
                onChanged: (_) => _calculateDays(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormBuilderDateTimePicker(
                name: 'endDate',
                inputType: InputType.date,
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  prefixIcon: Icon(Icons.event),
                ),
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                validator: (value) {
                  if (value == null) return 'End date is required';
                  final startDate = _formKey.currentState?.value['startDate'];
                  if (startDate != null && value.isBefore(startDate)) {
                    return 'End date must be after start date';
                  }
                  return null;
                },
                onChanged: (_) => _calculateDays(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHalfDaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormBuilderCheckbox(
          name: 'isHalfDay',
          title: const Text('Half Day Request'),
          onChanged: (value) {
            setState(() {
              _isHalfDay = value ?? false;
            });
            _calculateDays();
          },
        ),
        if (_isHalfDay) ...[
          const SizedBox(height: 12),
          FormBuilderRadioGroup<String>(
            name: 'halfDayPeriod',
            decoration: const InputDecoration(
              labelText: 'Half Day Period',
            ),
            options: const [
              FormBuilderFieldOption(value: 'morning', child: Text('Morning')),
              FormBuilderFieldOption(value: 'afternoon', child: Text('Afternoon')),
            ],
            validator: _isHalfDay ? FormBuilderValidators.required() : null,
          ),
        ],
      ],
    );
  }

  Widget _buildDaysCalculation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Days:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _calculatedDays.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalanceCheck(user) {
    final balance = user.leaveBalance[_selectedLeaveType!.id] ?? 0.0;
    final hasEnoughBalance = balance >= _calculatedDays;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasEnoughBalance ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasEnoughBalance ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasEnoughBalance ? Icons.check_circle : Icons.warning,
            color: hasEnoughBalance ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedLeaveType!.name} Balance',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  hasEnoughBalance
                      ? 'Available: ${balance.toStringAsFixed(1)} days'
                      : 'Insufficient balance: ${balance.toStringAsFixed(1)} days available',
                  style: TextStyle(
                    color: hasEnoughBalance ? Colors.green.shade700 : Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: 'reason',
          decoration: const InputDecoration(
            labelText: 'Enter reason for leave',
            prefixIcon: Icon(Icons.notes),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
            FormBuilderValidators.minLength(10),
          ]),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AuthProvider authProvider, LeaveProvider leaveProvider) {
    final user = authProvider.currentUser!;
    final hasEnoughBalance = _selectedLeaveType != null 
        ? (user.leaveBalance[_selectedLeaveType!.id] ?? 0.0) >= _calculatedDays
        : false;

    return ElevatedButton(
      onPressed: (leaveProvider.isLoading || !hasEnoughBalance) 
          ? null 
          : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: leaveProvider.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Submit Leave Request'),
    );
  }

  void _calculateDays() {
    final formData = _formKey.currentState?.value;
    if (formData != null && 
        formData['startDate'] != null && 
        formData['endDate'] != null) {
      
      final startDate = formData['startDate'] as DateTime;
      final endDate = formData['endDate'] as DateTime;
      final isHalfDay = formData['isHalfDay'] ?? false;
      
      if (isHalfDay && startDate.isAtSameMomentAs(endDate)) {
        setState(() {
          _calculatedDays = 0.5;
        });
      } else {
        final days = endDate.difference(startDate).inDays + 1;
        setState(() {
          _calculatedDays = days.toDouble();
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final authProvider = context.read<AuthProvider>();
      final leaveProvider = context.read<LeaveProvider>();
      
      final user = authProvider.currentUser!;
      
      final leaveRequest = LeaveRequest(
        id: '', // Will be set by database
        userId: user.id,
        leaveTypeId: _selectedLeaveType!.id,
        startDate: formData['startDate'],
        endDate: formData['endDate'],
        totalDays: _calculatedDays,
        reason: formData['reason'],
        status: LeaveStatus.pending,
        managerId: user.managerId,
        isHalfDay: _isHalfDay,
        halfDayPeriod: _isHalfDay ? formData['halfDayPeriod'] : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await leaveProvider.submitLeaveRequest(leaveRequest);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(leaveProvider.errorMessage ?? 'Failed to submit request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}