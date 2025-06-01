import 'package:flutter/material.dart';

class AddResourceDialog extends StatefulWidget {
  final String tournamentId;
  final Function(Map<String, dynamic>) onResourceAdded;

  const AddResourceDialog({
    super.key,
    required this.tournamentId,
    required this.onResourceAdded,
  });

  @override
  State<AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends State<AddResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();

  final List<String> _commonTypes = [
    'Court',
    'Field',
    'Table',
    'Pitch',
    'Pool',
    'Arena',
    'Stadium',
    'Room',
  ];

  String? _selectedType;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Resource'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Resource Name',
                    hintText: 'e.g., Court 1, Main Field',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a resource name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Resource Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _commonTypes.map((type) {
                    return DropdownMenuItem(
                      value: type.toLowerCase(),
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      _typeController.text = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a resource type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Additional details about this resource',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Capacity (Optional)',
                    hintText: 'Maximum number of simultaneous games',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isNotEmpty == true) {
                      final capacity = int.tryParse(value!);
                      if (capacity == null || capacity <= 0) {
                        return 'Please enter a valid positive number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (Optional)',
                    hintText: 'e.g., Building A, North Side',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitForm,
          child: const Text('Add Resource'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final resourceData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'type': _selectedType!,
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'capacity': _capacityController.text.trim().isEmpty 
            ? null 
            : int.parse(_capacityController.text.trim()),
        'location': _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
      };

      widget.onResourceAdded(resourceData);
      Navigator.of(context).pop();
    }
  }
} 