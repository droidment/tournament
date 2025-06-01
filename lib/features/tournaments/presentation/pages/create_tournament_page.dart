import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../bloc/tournament_bloc.dart';
import '../../bloc/tournament_event.dart';
import '../../bloc/tournament_state.dart';
import '../../data/models/tournament_model.dart';

class CreateTournamentPage extends StatefulWidget {
  const CreateTournamentPage({super.key});

  @override
  State<CreateTournamentPage> createState() => _CreateTournamentPageState();
}

class _CreateTournamentPageState extends State<CreateTournamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _rulesController = TextEditingController();
  final _prizeController = TextEditingController();

  TournamentFormat _selectedFormat = TournamentFormat.roundRobin;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;
  bool _createTriggered = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxTeamsController.dispose();
    _rulesController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  void _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Select Start Date',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 1));
        }
      });
    }
  }

  void _selectEndDate() async {
    final initialDate = _endDate ?? 
        (_startDate?.add(const Duration(days: 1)) ?? 
         DateTime.now().add(const Duration(days: 8)));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Select End Date',
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _selectRegistrationDeadline() async {
    final initialDate = _registrationDeadline ?? 
        (_startDate?.subtract(const Duration(days: 1)) ?? 
         DateTime.now().add(const Duration(days: 6)));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: _startDate ?? DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Select Registration Deadline',
    );

    if (picked != null) {
      setState(() {
        _registrationDeadline = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an end date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<TournamentBloc>().add(
          TournamentCreateRequested(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            format: _selectedFormat,
            startDate: _startDate!,
            endDate: _endDate!,
          ),
        );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDisplayName(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.roundRobin:
        return 'Round Robin';
      case TournamentFormat.singleElimination:
        return 'Single Elimination';
      case TournamentFormat.doubleElimination:
        return 'Double Elimination';
      case TournamentFormat.swiss:
        return 'Swiss System';
      case TournamentFormat.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<TournamentBloc, TournamentState>(
        listener: (context, state) {
          if (state.status == TournamentBlocStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tournament created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state.status == TournamentBlocStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to create tournament'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a tournament name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TournamentFormat>(
                  value: _selectedFormat,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Format',
                    border: OutlineInputBorder(),
                  ),
                  items: TournamentFormat.values.map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(_formatDisplayName(format)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFormat = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildDateSelector(
                  'Start Date',
                  _startDate,
                  (date) => setState(() => _startDate = date),
                ),
                const SizedBox(height: 16),
                _buildDateSelector(
                  'End Date',
                  _endDate,
                  (date) => setState(() => _endDate = date),
                ),
                const SizedBox(height: 32),
                BlocBuilder<TournamentBloc, TournamentState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == TournamentBlocStatus.creating
                          ? null
                          : _submitForm,
                      child: state.status == TournamentBlocStatus.creating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Tournament'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Next Steps',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'After creating your tournament:',
                        style: TextStyle(color: Colors.blue.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Set up categories (Men\'s/Women\'s, etc.)',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                      ),
                      Text(
                        '• Add teams and players',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                      ),
                      Text(
                        '• Configure tournament rules',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime? selectedDate,
    ValueChanged<DateTime> onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
              : 'Select $label',
          style: TextStyle(
            color: selectedDate != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }
} 