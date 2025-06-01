import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/category_bloc.dart';
import '../../bloc/category_state.dart';
import '../../../../core/models/team_model.dart';

class EditTeamDialog extends StatefulWidget {
  final TeamModel team;
  final Function(Map<String, dynamic>) onTeamUpdated;

  const EditTeamDialog({
    super.key,
    required this.team,
    required this.onTeamUpdated,
  });

  @override
  State<EditTeamDialog> createState() => _EditTeamDialogState();
}

class _EditTeamDialogState extends State<EditTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _seedController;
  
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.name);
    _descriptionController = TextEditingController(text: widget.team.description ?? '');
    _contactEmailController = TextEditingController(text: widget.team.contactEmail ?? '');
    _contactPhoneController = TextEditingController(text: widget.team.contactPhone ?? '');
    _seedController = TextEditingController(text: widget.team.seed?.toString() ?? '');
    _selectedCategoryId = widget.team.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Team'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a team name';
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
              BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state.categories.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  return DropdownButtonFormField<String?>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No Category'),
                      ),
                      ...state.categories.map((category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactEmailController,
                decoration: const InputDecoration(
                  labelText: 'Contact Email (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _seedController,
                decoration: const InputDecoration(
                  labelText: 'Seed (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final number = int.tryParse(value.trim());
                    if (number == null || number < 1) {
                      return 'Seed must be a positive number';
                    }
                  }
                  return null;
                },
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
          child: const Text('Update Team'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final teamData = <String, dynamic>{};
    
    // Only include changed fields
    if (_nameController.text.trim() != widget.team.name) {
      teamData['name'] = _nameController.text.trim();
    }
    
    final newDescription = _descriptionController.text.trim().isEmpty 
        ? null 
        : _descriptionController.text.trim();
    if (newDescription != widget.team.description) {
      teamData['description'] = newDescription;
    }
    
    if (_selectedCategoryId != widget.team.categoryId) {
      teamData['categoryId'] = _selectedCategoryId;
    }
    
    final newContactEmail = _contactEmailController.text.trim().isEmpty 
        ? null 
        : _contactEmailController.text.trim();
    if (newContactEmail != widget.team.contactEmail) {
      teamData['contactEmail'] = newContactEmail;
    }
    
    final newContactPhone = _contactPhoneController.text.trim().isEmpty 
        ? null 
        : _contactPhoneController.text.trim();
    if (newContactPhone != widget.team.contactPhone) {
      teamData['contactPhone'] = newContactPhone;
    }
    
    final newSeed = _seedController.text.trim().isEmpty 
        ? null 
        : int.parse(_seedController.text.trim());
    if (newSeed != widget.team.seed) {
      teamData['seed'] = newSeed;
    }

    // Only call the callback if there are changes
    if (teamData.isNotEmpty) {
      widget.onTeamUpdated(teamData);
    }
    
    Navigator.of(context).pop();
  }
} 