import 'package:flutter/material.dart';
import '../../../../core/models/game_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/tournament_resource_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/repositories/tournament_resource_repository.dart';
import '../../data/repositories/category_repository.dart';

class CreateGameDialog extends StatefulWidget {
  final String tournamentId;
  final Function(GameModel) onGameCreated;

  const CreateGameDialog({
    super.key,
    required this.tournamentId,
    required this.onGameCreated,
  });

  @override
  State<CreateGameDialog> createState() => _CreateGameDialogState();
}

class _CreateGameDialogState extends State<CreateGameDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Repositories
  final GameRepository _gameRepository = GameRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final TournamentResourceRepository _resourceRepository = TournamentResourceRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  // Form controllers
  final _roundController = TextEditingController();
  final _roundNameController = TextEditingController();
  final _gameNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _estimatedDurationController = TextEditingController(text: '60');
  
  // Form state
  CategoryModel? _selectedCategory;
  TeamModel? _selectedTeam1;
  TeamModel? _selectedTeam2;
  TournamentResourceModel? _selectedResource;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isPublished = false;
  bool _isLoading = false;
  
  // Data lists
  List<CategoryModel> _categories = [];
  List<TeamModel> _teams = [];
  List<TournamentResourceModel> _resources = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roundController.dispose();
    _roundNameController.dispose();
    _gameNumberController.dispose();
    _notesController.dispose();
    _estimatedDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _categoryRepository.getTournamentCategories(widget.tournamentId);
      final teams = await _teamRepository.getTournamentTeams(widget.tournamentId);
      final resources = await _resourceRepository.getTournamentResources(widget.tournamentId);
      
      setState(() {
        _categories = categories;
        _teams = teams;
        _resources = resources;
      });
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Create New Game',
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
            
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Details'),
                Tab(icon: Icon(Icons.group), text: 'Teams'),
                Tab(icon: Icon(Icons.schedule), text: 'Schedule'),
              ],
            ),
            
            // Tab content
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDetailsTab(),
                    _buildTeamsTab(),
                    _buildScheduleTab(),
                  ],
                ),
              ),
            ),
            
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
                  onPressed: _isLoading ? null : _createGame,
                  child: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Game'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category selection
          Text(
            'Category (Optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<CategoryModel>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select category',
            ),
            items: [
              const DropdownMenuItem<CategoryModel>(
                value: null,
                child: Text('No Category'),
              ),
              ..._categories.map((category) => DropdownMenuItem(
                value: category,
                child: Text(category.name),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Round information
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Round Number',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _roundController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 1',
                      ),
                      keyboardType: TextInputType.number,
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
                      'Game Number',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _gameNumberController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 1',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Round name
          Text(
            'Round Name (Optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _roundNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g., Quarterfinals, Semifinals, Finals',
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Estimated duration
          Text(
            'Estimated Duration (minutes)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _estimatedDurationController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '60',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter duration';
              }
              final duration = int.tryParse(value);
              if (duration == null || duration <= 0) {
                return 'Please enter a valid duration';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Notes
          Text(
            'Notes (Optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Additional information about this game',
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 20),
          
          // Published toggle
          SwitchListTile(
            title: const Text('Publish Game'),
            subtitle: const Text('Make this game visible to participants'),
            value: _isPublished,
            onChanged: (value) {
              setState(() {
                _isPublished = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_teams.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.group_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No teams available',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create teams first before scheduling games',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Team 1 selection
            Text(
              'Team 1 (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TeamModel>(
              value: _selectedTeam1,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Team 1',
              ),
              items: [
                const DropdownMenuItem<TeamModel>(
                  value: null,
                  child: Text('No Team Selected'),
                ),
                ..._teams.map((team) => DropdownMenuItem(
                  value: team,
                  child: Text(team.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTeam1 = value;
                  // Prevent selecting the same team twice
                  if (_selectedTeam2 == value) {
                    _selectedTeam2 = null;
                  }
                });
              },
            ),
            
            const SizedBox(height: 20),
            
            // Team 2 selection
            Text(
              'Team 2 (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TeamModel>(
              value: _selectedTeam2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Team 2',
              ),
              items: [
                const DropdownMenuItem<TeamModel>(
                  value: null,
                  child: Text('No Team Selected'),
                ),
                ..._teams.where((team) => team != _selectedTeam1).map((team) => DropdownMenuItem(
                  value: team,
                  child: Text(team.name),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTeam2 = value;
                });
              },
            ),
            
            const SizedBox(height: 20),
            
            // Teams preview
            if (_selectedTeam1 != null && _selectedTeam2 != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Match Preview',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTeam1!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Text(
                          ' vs ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _selectedTeam2!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selection
          Text(
            'Game Date',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
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
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Time selection
          Text(
            'Game Time',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Resource selection
          Text(
            'Resource (Optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<TournamentResourceModel>(
            value: _selectedResource,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select a resource',
            ),
            items: [
              const DropdownMenuItem<TournamentResourceModel>(
                value: null,
                child: Text('No Resource'),
              ),
              ..._resources.map((resource) => DropdownMenuItem(
                value: resource,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.name),
                    Text(
                      '${resource.type} - ${resource.location}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedResource = value;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Schedule summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                Text('Time: ${_selectedTime.format(context)}'),
                Text('Duration: ${_estimatedDurationController.text} minutes'),
                if (_selectedResource != null)
                  Text('Resource: ${_selectedResource!.name}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final game = await _gameRepository.createGame(
        tournamentId: widget.tournamentId,
        categoryId: _selectedCategory?.id,
        round: _roundController.text.isNotEmpty ? int.tryParse(_roundController.text) : null,
        roundName: _roundNameController.text.isNotEmpty ? _roundNameController.text : null,
        gameNumber: _gameNumberController.text.isNotEmpty ? int.tryParse(_gameNumberController.text) : null,
        team1Id: _selectedTeam1?.id,
        team2Id: _selectedTeam2?.id,
        resourceId: _selectedResource?.id,
        scheduledDate: _selectedDate,
        scheduledTime: _formatTime(_selectedTime),
        estimatedDuration: int.parse(_estimatedDurationController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isPublished: _isPublished,
      );

      widget.onGameCreated(game);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 