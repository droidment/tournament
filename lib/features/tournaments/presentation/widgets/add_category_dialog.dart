import 'package:flutter/material.dart';

class AddCategoryDialog extends StatefulWidget {
  final String tournamentId;
  final Function(Map<String, dynamic>) onCategoryAdded;

  const AddCategoryDialog({
    super.key,
    required this.tournamentId,
    required this.onCategoryAdded,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _minTeamsController = TextEditingController(text: '2');

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _maxTeamsController.dispose();
    _minTeamsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g., Men\'s, Women\'s, Mixed',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description of this category',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minTeamsController,
                      decoration: const InputDecoration(
                        labelText: 'Min Teams',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final number = int.tryParse(value.trim());
                        if (number == null || number < 1) {
                          return 'Must be at least 1';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxTeamsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Teams (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final number = int.tryParse(value.trim());
                          if (number == null || number < 1) {
                            return 'Must be at least 1';
                          }
                          final minTeams = int.tryParse(_minTeamsController.text.trim()) ?? 2;
                          if (number < minTeams) {
                            return 'Must be ≥ min teams';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Teams can be assigned to categories when creating or editing them.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          child: const Text('Add Category'),
        ),
      ],
    );
  }

  void _submitForm() {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      // Parse integers with error handling
      int minTeams;
      int? maxTeams;
      
      try {
        minTeams = int.parse(_minTeamsController.text.trim());
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid minimum teams value')),
        );
        return;
      }
      
      if (_maxTeamsController.text.trim().isNotEmpty) {
        try {
          maxTeams = int.parse(_maxTeamsController.text.trim());
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid maximum teams value')),
          );
          return;
        }
      }

      final categoryData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'minTeams': minTeams,
        'maxTeams': maxTeams,
      };

      try {
        widget.onCategoryAdded(categoryData);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        return;
      }
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
    }
  }
} 