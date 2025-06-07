import 'package:flutter/material.dart';
import 'package:teamapp3/core/models/team_model.dart';
import 'package:teamapp3/core/models/tournament_resource_model.dart';
import 'package:teamapp3/core/models/game_model.dart';
import 'package:teamapp3/features/tournaments/data/models/category_model.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';
import 'package:teamapp3/features/tournaments/data/repositories/team_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_resource_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/category_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_repository.dart';
import 'package:teamapp3/features/tournaments/data/services/schedule_generator_service.dart';

class GenerateScheduleDialog extends StatefulWidget {

  const GenerateScheduleDialog({
    super.key,
    required this.tournamentId,
    required this.onScheduleGenerated,
  });
  final String tournamentId;
  final Function(List<GameModel>) onScheduleGenerated;

  @override
  State<GenerateScheduleDialog> createState() => _GenerateScheduleDialogState();
}

class _GenerateScheduleDialogState extends State<GenerateScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Services and repositories
  final ScheduleGeneratorService _scheduleService = ScheduleGeneratorService();
  final TeamRepository _teamRepository = TeamRepository();
  final TournamentResourceRepository _resourceRepository = TournamentResourceRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final TournamentRepository _tournamentRepository = TournamentRepository();
  
  // Form controllers
  final _gameDurationController = TextEditingController(text: '60');
  final _breakDurationController = TextEditingController(text: '15');
  final _minimumRestController = TextEditingController(text: '120'); // Default 2 hours
  
  // Form state
  CategoryModel? _selectedCategory;
  DateTime _startDate = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  DateTime _endDate = DateTime.now().add(const Duration(days: 7)).copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
  bool _publishGames = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  // Data lists
  List<CategoryModel> _categories = [];
  List<TeamModel> _teams = [];
  List<TournamentResourceModel> _resources = [];
  TournamentModel? _tournament;
  
  // Calculated values
  int _totalGames = 0;
  Duration _estimatedDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _gameDurationController.dispose();
    _breakDurationController.dispose();
    _minimumRestController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _categoryRepository.getTournamentCategories(widget.tournamentId);
      final teams = await _teamRepository.getTournamentTeams(widget.tournamentId);
      final resources = await _resourceRepository.getTournamentResources(widget.tournamentId);
      final tournament = await _tournamentRepository.getTournament(widget.tournamentId);
      
      setState(() {
        _categories = categories;
        _teams = teams;
        _resources = resources;
        _tournament = tournament;
        
        // Initialize dates with tournament dates if available
        if (tournament?.startDate != null && tournament?.endDate != null) {
          print('🗓️ Using tournament dates: ${tournament!.startDate} to ${tournament.endDate}');
          _startDate = tournament.startDate.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
          _endDate = tournament.endDate.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
        } else {
          print('⚠️ Tournament dates not available, using current date range');
          // Fallback to current dates if tournament dates aren't set
          _startDate = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
          _endDate = DateTime.now().add(const Duration(days: 7)).copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
        }
        
        _isLoadingData = false;
        _calculateStats();
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculateStats() {
    final filteredTeams = _selectedCategory != null
        ? _teams.where((team) => team.categoryId == _selectedCategory!.id).toList()
        : _teams;
    
    _totalGames = ScheduleGeneratorService.calculateRoundRobinGames(filteredTeams.length);
    
    _estimatedDuration = ScheduleGeneratorService.estimateTournamentDuration(
      totalGames: _totalGames,
      resourceCount: _resources.length,
      gameDurationMinutes: int.tryParse(_gameDurationController.text) ?? 60,
      breakBetweenGames: int.tryParse(_breakDurationController.text) ?? 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Generate Round Robin Schedule',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isLoadingData) ...[
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            ] else ...[
              // Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCard(),
                        const SizedBox(height: 20),
                        _buildSettingsCard(),
                        const SizedBox(height: 20),
                        _buildScheduleCard(),
                        const SizedBox(height: 20),
                        _buildPreviewCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            
            // Actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isLoading || !_canGenerate() ? null : _generateSchedule,
                  child: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate Schedule'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final filteredTeams = _selectedCategory != null
        ? _teams.where((team) => team.categoryId == _selectedCategory!.id).toList()
        : _teams;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tournament Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Tournament dates info
            if (_tournament != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.event, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Tournament Period:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_tournament!.endDate != null) ...[
                      Text('${_formatDate(_tournament!.startDate)} - ${_formatDate(_tournament!.endDate)}'),
                    ] else ...[
                      const Text('Tournament dates not set', style: TextStyle(color: Colors.orange)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Teams', '${filteredTeams.length}', Icons.group),
                ),
                Expanded(
                  child: _buildStatItem('Resources', '${_resources.length}', Icons.location_on),
                ),
                Expanded(
                  child: _buildStatItem('Categories', '${_categories.length}', Icons.category),
                ),
              ],
            ),
            if (filteredTeams.length < 2) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Need at least 2 teams to generate schedule'),
                    ),
                  ],
                ),
              ),
            ],
            if (_resources.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Need at least 1 resource to generate schedule'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Category filter
            Text(
              'Category (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<CategoryModel>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'All teams',
              ),
              items: [
                const DropdownMenuItem<CategoryModel>(
                  child: Text('All Teams'),
                ),
                ..._categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category.name),
                ),),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _calculateStats();
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Game and break duration
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game Duration (minutes)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _gameDurationController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '60',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final duration = int.tryParse(value ?? '');
                          if (duration == null || duration <= 0) {
                            return 'Invalid duration';
                          }
                          return null;
                        },
                        onChanged: (value) => _calculateStats(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Break Between Games (minutes)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _breakDurationController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '15',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final duration = int.tryParse(value ?? '');
                          if (duration == null || duration < 0) {
                            return 'Invalid break duration';
                          }
                          return null;
                        },
                        onChanged: (value) => _calculateStats(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Minimum rest interval
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minimum Rest Interval (minutes)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Minimum time between games for the same team (default: 120 minutes)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _minimumRestController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '120',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final duration = int.tryParse(value ?? '');
                          if (duration == null || duration < 0) {
                            return 'Invalid minimum rest interval';
                          }
                          return null;
                        },
                        onChanged: (value) => _calculateStats(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Publish toggle
            SwitchListTile(
              title: const Text('Publish Games'),
              subtitle: const Text('Make games visible to participants immediately'),
              value: _publishGames,
              onChanged: (value) {
                setState(() {
                  _publishGames = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tournament Dates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Text(
                                '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
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
                      Text(
                        'End Date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Text(
                                '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildPreviewItem('Total Games', '$_totalGames', Icons.sports_soccer),
                ),
                Expanded(
                  child: _buildPreviewItem(
                    'Estimated Duration', 
                    '${_estimatedDuration.inHours}h ${_estimatedDuration.inMinutes % 60}m',
                    Icons.schedule,
                  ),
                ),
              ],
            ),
            
            if (_totalGames > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Round Robin Format:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    const Text('• Every team plays every other team once'),
                    Text('• Games distributed across ${_resources.length} resource${_resources.length != 1 ? 's' : ''}'),
                    const Text('• Automatic scheduling with conflict avoidance'),
                    Text('• Prevents back-to-back games (${int.tryParse(_minimumRestController.text) ?? 120} min rest)'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.orange),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  bool _canGenerate() {
    final filteredTeams = _selectedCategory != null
        ? _teams.where((team) => team.categoryId == _selectedCategory!.id).toList()
        : _teams;
    
    return filteredTeams.length >= 2 && 
           _resources.isNotEmpty && 
           _startDate.isBefore(_endDate);
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        // Set to start of day (00:00:00)
        _startDate = picked.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
        if (_endDate.isBefore(_startDate)) {
          // Set end date to end of day, 7 days later
          _endDate = _startDate.add(const Duration(days: 7)).copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
        }
        _calculateStats();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        // Set to end of day (23:59:59)
        _endDate = picked.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
        _calculateStats();
      });
    }
  }

  Future<void> _generateSchedule() async {
    if (!_formKey.currentState!.validate() || !_canGenerate()) return;

    setState(() => _isLoading = true);

    try {
      final filteredTeams = _selectedCategory != null
          ? _teams.where((team) => team.categoryId == _selectedCategory!.id).toList()
          : _teams;

      final games = await _scheduleService.generateRoundRobinSchedule(
        tournamentId: widget.tournamentId,
        teams: filteredTeams,
        resources: _resources,
        startDate: _startDate,
        endDate: _endDate,
        gameDurationMinutes: int.parse(_gameDurationController.text),
        timeBetweenGamesMinutes: int.parse(_breakDurationController.text),
        categoryId: _selectedCategory?.id,
        minimumRestMinutes: int.parse(_minimumRestController.text),
      );

      widget.onScheduleGenerated(games);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated ${games.length} games successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 