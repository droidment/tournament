import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_event.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_state.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';

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
  final bool _createTriggered = false;

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
      case TournamentFormat.tiered:
        return 'Tiered Tournament';
      case TournamentFormat.custom:
        return 'Custom';
    }
  }

  void _showTieredTournamentDemo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tiered Tournament Format',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDemoSection(
                        '🏟️ Overview',
                        'A three-phase tournament format that ensures competitive balance and gives every team a chance to succeed.',
                      ),
                      _buildDemoSection(
                        '📊 Phase 1: Group Stage',
                        '• Teams distributed across groups using snake-draft seeding\n'
                        '• Round-robin format within each group\n'
                        '• Configurable scoring system (2-1-0 default)\n'
                        '• Full tiebreaker system (points → head-to-head → point differential)',
                      ),
                      _buildDemoSection(
                        '🎯 Phase 2: Tier Classification',
                        '• Teams sorted into Pro, Intermediate, and Novice tiers\n'
                        '• Based on group stage performance\n'
                        '• Automatic elimination of lowest performers\n'
                        '• Ensures competitive balance in playoffs',
                      ),
                      _buildDemoSection(
                        '🏆 Phase 3: Tiered Playoffs',
                        '• Separate single-elimination brackets for each tier\n'
                        '• Pro Champion, Intermediate Champion, Novice Champion\n'
                        '• Teams seeded by tier performance\n'
                        '• Guaranteed competitive matches',
                      ),
                      _buildDemoSection(
                        '⭐ Key Benefits',
                        '• Every team gets significant playing time\n'
                        '• Three different winners, not just one\n'
                        '• Competitive balance at all skill levels\n'
                        '• Scales efficiently from 8 to 32+ teams\n'
                        '• Perfect for volleyball and pickleball',
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Example: 16 Teams',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• 4 groups of 4 teams each\n'
                              '• Group stage: 3 games per team\n'
                              '• Pro tier: 4 teams (1st place winners)\n'
                              '• Intermediate tier: 8 teams (2nd & 3rd place)\n'
                              '• Novice tier: 4 teams (4th place)\n'
                              '• Total games per team: 4-6 games',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedFormat = TournamentFormat.tiered;
                        });
                      },
                      child: const Text('Use Tiered Format'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Try multiple navigation approaches for robustness
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback: navigate to tournament management
              context.go('/tournaments');
            }
          },
          tooltip: 'Back to Tournament Management',
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
          padding: const EdgeInsets.all(16),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<TournamentFormat>(
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
                        ),
                        if (_selectedFormat == TournamentFormat.tiered) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _showTieredTournamentDemo,
                            icon: const Icon(Icons.help_outline),
                            tooltip: 'Learn about Tiered Tournaments',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_selectedFormat == TournamentFormat.tiered) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
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
                                Icon(Icons.info_outline, 
                                     color: Colors.blue.shade600, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Tiered Tournament Features',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '• Group stage with snake-draft seeding\n'
                              '• Tier classification (Pro/Intermediate/Novice)\n'
                              '• Separate elimination brackets for each tier\n'
                              '• Three different champions',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
                        "• Set up categories (Men's/Women's, etc.)",
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
              ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
              : 'Select $label',
          style: TextStyle(
            color: selectedDate != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }
} 