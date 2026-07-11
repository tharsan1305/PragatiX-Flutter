import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:spdms_app/core/config/api_config.dart';

class EditStagePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> stage;

  const EditStagePage({super.key, required this.token, required this.stage});

  @override
  State<EditStagePage> createState() => _EditStagePageState();
}

class _EditStagePageState extends State<EditStagePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _orderCtrl;
  
  DateTime? _startDate;
  DateTime? _endDate;
  late bool _isActive;
  bool _isSaving = false;

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    
    // Pre-populate fields from the stage map
    _nameCtrl = TextEditingController(text: widget.stage['name'] as String? ?? '');
    _descCtrl = TextEditingController(text: widget.stage['description'] as String? ?? '');
    _orderCtrl = TextEditingController(text: (widget.stage['displayOrder'] ?? 0).toString());
    
    _isActive = widget.stage['isActive'] as bool? ?? widget.stage['active'] as bool? ?? true;

    final startStr = widget.stage['startDate'] as String?;
    if (startStr != null && startStr.isNotEmpty) {
      try {
        _startDate = DateTime.parse(startStr);
      } catch (_) {}
    }
    
    final endStr = widget.stage['endDate'] as String?;
    if (endStr != null && endStr.isNotEmpty) {
      try {
        _endDate = DateTime.parse(endStr);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
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
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before new start date, reset end date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
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
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _updateStage() async {
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
    final stageId = widget.stage['id'];

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/admin/stages/$stageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
          'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
          'displayOrder': int.tryParse(_orderCtrl.text.trim()) ?? 0,
          'isActive': _isActive,
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stage updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to update stage'),
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
        title: const Text('Edit Stage', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                      'Modify Stage',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update settings, dates, display order, or status for this program stage.',
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
                                  _startDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_startDate!),
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
                                  _endDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_endDate!),
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
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text('Active Status', style: TextStyle(fontWeight: FontWeight.bold, color: _dark)),
                        subtitle: const Text('Only active stages enforce date restrictions and thresholds.'),
                        value: _isActive,
                        activeColor: _primary,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateStage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
