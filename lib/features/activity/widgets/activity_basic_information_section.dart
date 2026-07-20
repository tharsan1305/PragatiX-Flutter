import 'package:flutter/material.dart';
import '../utils/validators.dart';

class ActivityBasicInformationSection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController displayOrderCtrl;
  final String? selectedXpCategory;
  final String selectedStatus;
  final bool submitted;
  final ValueChanged<String?> onXpCategoryChanged;
  final ValueChanged<String?> onStatusChanged;

  const ActivityBasicInformationSection({
    super.key,
    required this.nameCtrl,
    required this.descCtrl,
    required this.displayOrderCtrl,
    this.selectedXpCategory,
    required this.selectedStatus,
    required this.submitted,
    required this.onXpCategoryChanged,
    required this.onStatusChanged,
  });

  static const Color _primary = Color(0xFFEA4335);
  static const Color _dark = Color(0xFF1E293B);
  static const Color _surface = Color(0xFFF8FAFC);

  static const List<String> _xpCategories = [
    'Academic', 'Skill', 'Communication', 'Leadership', 'Discipline',
    'Placement', 'Innovation', 'Community', 'Sports', 'Cultural',
  ];

  InputDecoration _deco(String label, IconData icon, {bool alignHint = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      alignLabelWithHint: alignHint,
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: nameCtrl,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Event Name', Icons.title_rounded),
          validator: ActivityValidators.validateName,
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: _deco('XP Category', Icons.category_rounded).copyWith(
            errorText: (submitted && selectedXpCategory == null) ? 'XP Category is required' : null,
          ),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: selectedXpCategory,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            hint: const Text('Select XP Category', style: TextStyle(fontSize: 14)),
            items: _xpCategories.map((c) {
              return DropdownMenuItem<String>(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 14, color: _dark)),
              );
            }).toList(),
            onChanged: onXpCategoryChanged,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descCtrl,
          maxLines: 3,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Description', Icons.notes_rounded, alignHint: true),
          validator: ActivityValidators.validateDescription,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: displayOrderCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _dark, fontSize: 15),
          decoration: _deco('Display Order', Icons.sort_rounded),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Display order is required';
            if (int.tryParse(val) == null) return 'Must be a valid integer';
            return null;
          },
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: _deco('Status', Icons.check_circle_outline_rounded),
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            value: selectedStatus,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.expand_more_rounded, color: _primary),
            items: const [
              DropdownMenuItem<String>(value: 'ACTIVE', child: Text('Active', style: TextStyle(fontSize: 14, color: _dark))),
              DropdownMenuItem<String>(value: 'INACTIVE', child: Text('Inactive', style: TextStyle(fontSize: 14, color: _dark))),
            ],
            onChanged: onStatusChanged,
          ),
        ),
      ],
    );
  }
}
