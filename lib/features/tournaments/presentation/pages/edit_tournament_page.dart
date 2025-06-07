import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_event.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_state.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';

class EditTournamentPage extends StatefulWidget {
  final String tournamentId;

  const EditTournamentPage({
    super.key,
    required this.tournamentId,
  });

  @override
  State<EditTournamentPage> createState() => _EditTournamentPageState();
}

class _EditTournamentPageState extends State<EditTournamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _rulesController = TextEditingController();
  final _prizeController = TextEditingController();

  TournamentFormat? _selectedFormat;
  TournamentStatus? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationDeadline;
  bool _isLoading = true;
  TournamentModel? _originalTournament;

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  void _loadTournament() {
    context.read<TournamentBloc>().add(
      TournamentLoadRequested(widget.tournamentId),
    );
  }

  void _populateFields(TournamentModel tournament) {
    setState(() {
      _originalTournament = tournament;
      _nameController.text = tournament.name;
      _descriptionController.text = tournament.description ?? '';
      _selectedFormat = tournament.format;
      _selectedStatus = tournament.status;
      _startDate = tournament.startDate;
      _endDate = tournament.endDate;
      _isLoading = false;
    });
  }

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

  Future<void> _selectStartDate() async {
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

  Future<void> _selectEndDate() async {
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

  Future<void> _selectRegistrationDeadline() async {
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
      TournamentUpdateRequested(
        tournamentId: widget.tournamentId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        format: _selectedFormat,
        status: _selectedStatus,
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
      case TournamentFormat.tiered:
        return 'Tiered Tournament';
      case TournamentFormat.custom:
        return 'Custom';
    }
  }

  String _formatStatusDisplayName(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return 'Draft';
      case TournamentStatus.registration:
        return 'Registration Open';
      case TournamentStatus.inProgress:
        return 'In Progress';
      case TournamentStatus.completed:
        return 'Completed';
      case TournamentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getStatusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return Colors.grey;
      case TournamentStatus.registration:
        return Colors.blue;
      case TournamentStatus.inProgress:
        return Colors.orange;
      case TournamentStatus.completed:
        return Colors.green;
      case TournamentStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tournament'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tournaments');
            }
          },
          tooltip: 'Back',
        ),
      ),
      body: BlocListener<TournamentBloc, TournamentState>(
        listener: (context, state) {
          if (state.status == TournamentBlocStatus.success && state.tournament != null) {
            if (!_isLoading && state.tournament!.id == widget.tournamentId) {
              // Tournament was updated successfully
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tournament updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              context.pop();
            } else if (_isLoading) {
              // Tournament was loaded for editing
              _populateFields(state.tournament!);
            }
          } else if (state.status == TournamentBlocStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to update tournament'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<TournamentBloc, TournamentState>(
          builder: (context, state) {
            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tournament Info Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tournament Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ID: ${widget.tournamentId}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            if (_originalTournament?.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${_formatDate(_originalTournament!.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Basic Information
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tournament Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sports_esports),
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
                        prefixIcon: Icon(Icons.description),
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

                    // Format and Status Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TournamentFormat>(
                            value: _selectedFormat,
                            decoration: const InputDecoration(
                              labelText: 'Tournament Format',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.format_list_bulleted),
                            ),
                            items: TournamentFormat.values.map((format) {
                              return DropdownMenuItem(
                                value: format,
                                child: Text(_formatDisplayName(format)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFormat = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a format';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<TournamentStatus>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Tournament Status',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag),
                            ),
                            items: TournamentStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_formatStatusDisplayName(status)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a status';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date Selection
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectStartDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(_formatDate(_startDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectEndDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.event),
                              ),
                              child: Text(_formatDate(_endDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/tournaments');
                              }
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: state.isUpdating ? null : _submitForm,
                            child: state.isUpdating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Update Tournament'),
                          ),
                        ),
                      ],
                    ),

                    // Warning for active tournaments
                    if (_selectedStatus == TournamentStatus.inProgress ||
                        _selectedStatus == TournamentStatus.completed) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Be careful when editing active or completed tournaments. Changes may affect existing schedules and results.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
} 