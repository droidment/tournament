import 'package:flutter/material.dart';
import 'package:teamapp3/features/tournaments/data/models/category_model.dart';

class EditCategoryDialog extends StatefulWidget {

  const EditCategoryDialog({
    super.key,
    required this.category,
    required this.onCategoryUpdated,
  });
  final CategoryModel category;
  final Function(Map<String, dynamic>) onCategoryUpdated;

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxTeamsController;
  late final TextEditingController _minTeamsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _descriptionController = TextEditingController(text: widget.category.description ?? '');
    _maxTeamsController = TextEditingController(
      text: widget.category.maxTeams?.toString() ?? '',
    );
    _minTeamsController = TextEditingController(
      text: widget.category.minTeams.toString(),
    );
  }

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
      title: const Text('Edit Category'),
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
          child: const Text('Update Category'),
        ),
      ],
    );
  }

  void _submitForm() {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final categoryData = <String, dynamic>{};
      
      // Only include changed fields
      if (_nameController.text.trim() != widget.category.name) {
        categoryData['name'] = _nameController.text.trim();
      }
      
      final newDescription = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();
      if (newDescription != widget.category.description) {
        categoryData['description'] = newDescription;
      }
      
      try {
        final newMinTeams = int.parse(_minTeamsController.text.trim());
        if (newMinTeams != widget.category.minTeams) {
          categoryData['minTeams'] = newMinTeams;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid minimum teams value')),
        );
        return;
      }
      
      if (_maxTeamsController.text.trim().isNotEmpty) {
        try {
          final newMaxTeams = int.parse(_maxTeamsController.text.trim());
          if (newMaxTeams != widget.category.maxTeams) {
            categoryData['maxTeams'] = newMaxTeams;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid maximum teams value')),
          );
          return;
        }
      } else {
        // Handle case where maxTeams field is cleared
        if (widget.category.maxTeams != null) {
          categoryData['maxTeams'] = null;
        }
      }

      // Only call the callback if there are changes
      if (categoryData.isNotEmpty) {
        try {
          widget.onCategoryUpdated(categoryData);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e}')),
          );
          return;
        }
      }
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e}')),
      );
    }
  }
} 