import 'package:spdms_app/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:spdms_app/features/activity/services/activity_proxy_service.dart';
import 'package:intl/intl.dart';
import 'package:spdms_app/core/config/api_config.dart';
import 'package:spdms_app/core/di/service_locator.dart';

class CreateStagePage extends StatefulWidget {
  const CreateStagePage({super.key, });

  @override
  State<CreateStagePage> createState() => _CreateStagePageState();
}

class _CreateStagePageState extends State<CreateStagePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _orderCtrl = TextEditingController(text: '0');
  final _expectedXpCtrl = TextEditingController(text: '0');
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  bool _useDateValidation = true;
  bool _useThresholdValidation = false;
  bool _useCombinedValidation = false;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    _expectedXpCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: _dark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _startDate != null ? TimeOfDay.fromDateTime(_startDate!) : TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        setState(() {
          _startDate = newDateTime;
          // If end date is before new start date, reset end date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        });
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: _dark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _endDate != null ? TimeOfDay.fromDateTime(_endDate!) : TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        setState(() {
          _endDate = newDateTime;
        });
      }
    }
  }

  Future<void> _saveStage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Start and End dates'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End Date cannot be before Start Date'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await getIt<ActivityProxyService>().post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/stages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${context.read<AuthProvider>().token!}',
        },
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'expectedXp': int.tryParse(_expectedXpCtrl.text.trim()) ?? 0,
          'startDateTime': _startDate!.toIso8601String(),
          'endDateTime': _endDate!.toIso8601String(),
          'displayOrder': int.tryParse(_orderCtrl.text.trim()) ?? 0,
          'useDateValidation': _useDateValidation,
          'useThresholdValidation': _useThresholdValidation,
          'useCombinedValidation': _useCombinedValidation,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201 || (response.statusCode == 200 && data['success'] == true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stage created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to create stage'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Stage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _dark,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stage Configuration',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Define a new duration segment for the 3-Month Student Development Program.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Stage Name *',
                        hintText: 'e.g. Stage 1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Stage Name is required' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe targets or rules for this stage...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _expectedXpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Expected XP *',
                        hintText: 'e.g. 500',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Expected XP is required';
                        if (int.tryParse(v) == null) return 'Must be a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Date *', style: TextStyle(fontWeight: FontWeight.bold, color: _dark)),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _selectStartDate(context),
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  _startDate == null ? 'Select Date & Time' : DateFormat('dd MMM yyyy, HH:mm').format(_startDate!),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  foregroundColor: _startDate == null ? Colors.grey.shade700 : _primary,
                                  side: BorderSide(color: _startDate == null ? Colors.grey.shade400 : _primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Date *', style: TextStyle(fontWeight: FontWeight.bold, color: _dark)),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _selectEndDate(context),
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  _endDate == null ? 'Select Date & Time' : DateFormat('dd MMM yyyy, HH:mm').format(_endDate!),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  foregroundColor: _endDate == null ? Colors.grey.shade700 : _primary,
                                  side: BorderSide(color: _endDate == null ? Colors.grey.shade400 : _primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _orderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Display Order',
                        hintText: 'e.g. 1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (int.tryParse(v) == null) return 'Must be a valid integer';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Stage Unlock Rules Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Stage Unlock Rules',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _dark),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Use Start & End Date/Time', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Students can access this stage only during the configured Start DateTime and End DateTime.', style: TextStyle(fontSize: 12)),
                            value: _useDateValidation,
                            activeThumbColor: _primary,
                            onChanged: (val) => setState(() => _useDateValidation = val),
                          ),
                          const Divider(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Require Threshold Completion', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Students must complete all required subgroup thresholds before this stage unlocks.', style: TextStyle(fontSize: 12)),
                            value: _useThresholdValidation,
                            activeThumbColor: _primary,
                            onChanged: (val) => setState(() => _useThresholdValidation = val),
                          ),
                          const Divider(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Require BOTH Date & Threshold', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Students must satisfy BOTH Date & Time AND Thresholds before the stage unlocks.', style: TextStyle(fontSize: 12)),
                            value: _useCombinedValidation,
                            activeThumbColor: _primary,
                            onChanged: (val) => setState(() => _useCombinedValidation = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveStage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Create Stage',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}