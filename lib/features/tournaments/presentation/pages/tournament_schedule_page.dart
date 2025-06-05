import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/game_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/tournament_resource_model.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/repositories/tournament_resource_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../widgets/generate_schedule_dialog.dart';
import '../widgets/tournament_standings_widget.dart';
import '../../data/services/tournament_standings_service.dart';
import '../../data/services/export_service.dart';
import '../../data/models/tournament_model.dart';
import '../../../../core/models/tournament_standings_model.dart';

class TournamentSchedulePage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentSchedulePage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<TournamentSchedulePage> createState() => _TournamentSchedulePageState();
}

class _TournamentSchedulePageState extends State<TournamentSchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GameRepository _repository = GameRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final TournamentResourceRepository _resourceRepository = TournamentResourceRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  List<GameModel> _allGames = [];
  List<GameModel> _scheduledGames = [];
  List<GameModel> _completedGames = [];
  List<TeamModel> _teams = [];
  List<TournamentResourceModel> _resources = [];
  List<CategoryModel> _categories = [];
  Map<String, TeamModel> _teamMap = {};
  Map<String, TournamentResourceModel> _resourceMap = {};
  Map<String, CategoryModel> _categoryMap = {};
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  bool _isScheduleView = false;
  bool _isGridView = false;
  
  // Filter variables
  String? _selectedCategoryFilter;
  String? _selectedTeamFilter;
  String? _selectedResourceFilter;
  
  // Filtered games lists
  List<GameModel> _filteredAllGames = [];
  List<GameModel> _filteredScheduledGames = [];
  List<GameModel> _filteredCompletedGames = [];
  List<TeamModel> _filteredTeams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadGames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    
    try {
      final games = await _repository.getTournamentGames(widget.tournamentId);
      final stats = await _repository.getTournamentGameStats(widget.tournamentId);
      final teams = await _teamRepository.getTournamentTeams(widget.tournamentId);
      final resources = await _resourceRepository.getTournamentResources(widget.tournamentId);
      final categories = await _categoryRepository.getTournamentCategories(widget.tournamentId);
      
      // Create a map for quick team lookups
      final teamMap = <String, TeamModel>{};
      for (final team in teams) {
        teamMap[team.id] = team;
      }
      
      // Create a map for quick resource lookups
      final resourceMap = <String, TournamentResourceModel>{};
      for (final resource in resources) {
        resourceMap[resource.id] = resource;
      }
      
      // Create a map for quick category lookups
      final categoryMap = <String, CategoryModel>{};
      for (final category in categories) {
        categoryMap[category.id] = category;
      }
      
      setState(() {
        _allGames = games;
        _scheduledGames = games.where((g) => g.status == GameStatus.scheduled).toList();
        _completedGames = games.where((g) => g.status == GameStatus.completed).toList();
        _teams = teams;
        _resources = resources;
        _categories = categories;
        _teamMap = teamMap;
        _resourceMap = resourceMap;
        _categoryMap = categoryMap;
        _stats = stats;
        _isLoading = false;
      });
      
      // Apply filters after loading data
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading games: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      // Filter games based on selected filters
      _filteredAllGames = _filterGames(_allGames);
      _filteredScheduledGames = _filterGames(_scheduledGames);
      _filteredCompletedGames = _filterGames(_completedGames);
      
      // Filter teams for standings
      _filteredTeams = _filterTeams(_teams);
    });
  }

  List<GameModel> _filterGames(List<GameModel> games) {
    return games.where((game) {
      // Filter by category (using team category names or resource type)
      if (_selectedCategoryFilter != null && _selectedCategoryFilter!.isNotEmpty) {
        final team1 = _teamMap[game.team1Id];
        final team2 = _teamMap[game.team2Id];
        final resource = _resourceMap[game.resourceId];
        
        // Check if any associated entity matches the category filter
        bool matchesCategory = false;
        
        // Check team1 category
        if (team1?.categoryId != null) {
          final category1 = _categoryMap[team1!.categoryId!];
          if (category1?.name == _selectedCategoryFilter) {
            matchesCategory = true;
          }
        }
        
        // Check team2 category
        if (team2?.categoryId != null) {
          final category2 = _categoryMap[team2!.categoryId!];
          if (category2?.name == _selectedCategoryFilter) {
            matchesCategory = true;
          }
        }
        
        // Check resource type
        if (resource?.type == _selectedCategoryFilter) {
          matchesCategory = true;
        }
        
        if (!matchesCategory) return false;
      }
      
      // Filter by team
      if (_selectedTeamFilter != null && _selectedTeamFilter!.isNotEmpty) {
        if (game.team1Id != _selectedTeamFilter && game.team2Id != _selectedTeamFilter) {
          return false;
        }
      }
      
      // Filter by resource
      if (_selectedResourceFilter != null && _selectedResourceFilter!.isNotEmpty) {
        if (game.resourceId != _selectedResourceFilter) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  List<TeamModel> _filterTeams(List<TeamModel> teams) {
    return teams.where((team) {
      // Filter by category (using team category name)
      if (_selectedCategoryFilter != null && _selectedCategoryFilter!.isNotEmpty) {
        if (team.categoryId != null) {
          final category = _categoryMap[team.categoryId!];
          if (category?.name != _selectedCategoryFilter) {
            return false;
          }
        } else {
          // Team has no category, doesn't match category filter
          return false;
        }
      }
      
      // Filter by specific team
      if (_selectedTeamFilter != null && _selectedTeamFilter!.isNotEmpty) {
        if (team.id != _selectedTeamFilter) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters())
                TextButton(
                  onPressed: _clearAllFilters,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildCategoryFilter(),
              _buildTeamFilter(),
              _buildResourceFilter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = _getAvailableCategories();
    
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
      child: DropdownButtonFormField<String>(
        value: _selectedCategoryFilter,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: const Icon(Icons.category, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: false,
        ),
        style: const TextStyle(fontSize: 14),
        isExpanded: true,
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All Categories', style: TextStyle(fontSize: 14)),
          ),
          ...categories.map((category) => DropdownMenuItem<String>(
            value: category,
            child: Text(
              category,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
        onChanged: (value) {
          setState(() {
            _selectedCategoryFilter = value;
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildTeamFilter() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
      child: DropdownButtonFormField<String>(
        value: _selectedTeamFilter,
        decoration: InputDecoration(
          labelText: 'Team',
          prefixIcon: const Icon(Icons.group, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: false,
        ),
        style: const TextStyle(fontSize: 14),
        isExpanded: true,
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All Teams', style: TextStyle(fontSize: 14)),
          ),
          ..._teams.map((team) => DropdownMenuItem<String>(
            value: team.id,
            child: Text(
              team.name,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
        onChanged: (value) {
          setState(() {
            _selectedTeamFilter = value;
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildResourceFilter() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 200),
      child: DropdownButtonFormField<String>(
        value: _selectedResourceFilter,
        decoration: InputDecoration(
          labelText: 'Resource',
          prefixIcon: const Icon(Icons.place, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: false,
        ),
        style: const TextStyle(fontSize: 14),
        isExpanded: true,
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All Resources', style: TextStyle(fontSize: 14)),
          ),
          ..._resources.map((resource) => DropdownMenuItem<String>(
            value: resource.id,
            child: Text(
              resource.name,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
        onChanged: (value) {
          setState(() {
            _selectedResourceFilter = value;
          });
          _applyFilters();
        },
      ),
    );
  }

  List<String> _getAvailableCategories() {
    final categoryNames = <String>{};
    
    // Add team category names
    for (final team in _teams) {
      if (team.categoryId != null && team.categoryId!.isNotEmpty) {
        final category = _categoryMap[team.categoryId!];
        if (category != null) {
          categoryNames.add(category.name);
        }
      }
    }
    
    // Add resource types as categories
    for (final resource in _resources) {
      if (resource.type.isNotEmpty) {
        categoryNames.add(resource.type);
      }
    }
    
    return categoryNames.toList()..sort();
  }

  bool _hasActiveFilters() {
    return (_selectedCategoryFilter != null && _selectedCategoryFilter!.isNotEmpty) ||
           (_selectedTeamFilter != null && _selectedTeamFilter!.isNotEmpty) ||
           (_selectedResourceFilter != null && _selectedResourceFilter!.isNotEmpty);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryFilter = null;
      _selectedTeamFilter = null;
      _selectedResourceFilter = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.tournamentName} - Schedule'),
            if (_stats.isNotEmpty)
              Text(
                '${_stats['total_games']} games • ${_stats['completed']} completed',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.schedule),
              text: 'All Games (${_filteredAllGames.isNotEmpty ? _filteredAllGames.length : _allGames.length})',
            ),
            Tab(
              icon: const Icon(Icons.event),
              text: 'Scheduled (${_filteredScheduledGames.isNotEmpty ? _filteredScheduledGames.length : _scheduledGames.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text: 'Completed (${_filteredCompletedGames.isNotEmpty ? _filteredCompletedGames.length : _completedGames.length})',
            ),
            const Tab(
              icon: Icon(Icons.leaderboard),
              text: 'Standings',
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'generate':
                  _showGenerateScheduleDialog();
                  break;
                case 'refresh':
                  _loadGames();
                  break;
                case 'delete_all':
                  _showDeleteAllGamesDialog();
                  break;
                case 'export':
                  _showExportDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'generate',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high),
                    SizedBox(width: 8),
                    Text('Generate Schedule'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              if (_allGames.isNotEmpty) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete All Games', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Schedule'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_stats.isNotEmpty) _buildStatsHeader(),
                _buildFilterBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGamesTab(_hasActiveFilters() ? _filteredAllGames : _allGames, 'No games match the current filters'),
                      _buildGamesTab(_hasActiveFilters() ? _filteredScheduledGames : _scheduledGames, 'No scheduled games match the current filters'),
                      _buildGamesTab(_hasActiveFilters() ? _filteredCompletedGames : _completedGames, 'No completed games match the current filters'),
                      TournamentStandingsWidget(
                        standings: TournamentStandingsService.calculateStandings(
                          tournamentId: widget.tournamentId,
                          format: TournamentFormat.roundRobin, // Default format
                          games: _allGames, // Always use all games for accurate standings calculation
                          teams: _hasActiveFilters() ? _filteredTeams : _teams, // Filter teams for display
                          phase: 'tournament',
                        ),
                        format: TournamentFormat.roundRobin,
                        onRefresh: _loadGames,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGenerateScheduleDialog,
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Generate Schedule'),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', _stats['total_games'] as int, Colors.blue),
          _buildStatItem('Scheduled', _stats['scheduled'] as int, Colors.orange),
          _buildStatItem('In Progress', _stats['in_progress'] as int, Colors.green),
          _buildStatItem('Completed', _stats['completed'] as int, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildGamesTab(List<GameModel> games, String emptyMessage) {
    if (games.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: _loadGames,
      child: Column(
        children: [
          // View toggle controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'View:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'list',
                      label: Text('List'),
                      icon: Icon(Icons.list),
                    ),
                    ButtonSegment(
                      value: 'timeline',
                      label: Text('Timeline'),
                      icon: Icon(Icons.calendar_view_day),
                    ),
                    ButtonSegment(
                      value: 'grid',
                      label: Text('Grid'),
                      icon: Icon(Icons.grid_view),
                    ),
                  ],
                  selected: {_isScheduleView ? (_isGridView ? 'grid' : 'timeline') : 'list'},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      final selected = newSelection.first;
                      _isScheduleView = selected != 'list';
                      _isGridView = selected == 'grid';
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Content area - full screen for grid, padded for others
          Expanded(
            child: _isScheduleView 
                ? _isGridView 
                  ? _buildGridView(games) // Full screen grid
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildScheduleView(games),
                    )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildListView(games),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<GameModel> games) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return _buildGameCard(game);
        },
    );
  }

  Widget _buildScheduleView(List<GameModel> games) {
    // Group games by date and time
    final Map<String, Map<String, List<GameModel>>> schedule = {};
    
    for (final game in games) {
      if (game.scheduledDate != null && game.scheduledTime != null) {
        final dateKey = _formatDate(game.scheduledDate!);
        final timeKey = game.scheduledTime!;
        
        schedule.putIfAbsent(dateKey, () => {});
        schedule[dateKey]!.putIfAbsent(timeKey, () => []);
        schedule[dateKey]![timeKey]!.add(game);
      }
    }

    // Add common time slots even if empty
    final commonTimeSlots = [
      '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
      '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'
    ];

    // Ensure we have at least some dates to show
    if (schedule.isEmpty) {
      // If no games are scheduled, show today and next few days with empty slots
      final today = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = today.add(Duration(days: i));
        final dateKey = _formatDate(date);
        schedule[dateKey] = {};
        for (final timeSlot in commonTimeSlots) {
          schedule[dateKey]![timeSlot] = [];
        }
      }
    } else {
      // For existing dates, add empty time slots
      for (final dateKey in schedule.keys) {
        for (final timeSlot in commonTimeSlots) {
          schedule[dateKey]!.putIfAbsent(timeSlot, () => []);
        }
      }
    }

    if (schedule.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No scheduled games',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const Text('Games need dates and times to appear in schedule view'),
          ],
        ),
      );
    }

    // Sort dates chronologically
    final sortedDates = schedule.keys.toList()..sort((a, b) {
      final dateA = _parseDate(a);
      final dateB = _parseDate(b);
      return dateA.compareTo(dateB);
    });

    return Column(
      children: [
        // Instructions for drag and drop
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Drag games between time slots to reschedule. Green = valid drop zone, Red = team conflict.',
                  style: TextStyle(color: Colors.blue[800], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        
        ...sortedDates.map((dateKey) {
          return _buildDateSection(dateKey, schedule[dateKey]!);
        }),
      ],
    );
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split('/');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildDateSection(String date, Map<String, List<GameModel>> timeSlots) {
    final sortedTimes = timeSlots.keys.toList()..sort();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedTimes.map((time) {
              return _buildTimeSlot(date, time, timeSlots[time]!);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String date, String time, List<GameModel> games) {
    return DragTarget<GameModel>(
      onAcceptWithDetails: (details) => _handleGameDrop(details.data, date, time),
      onWillAcceptWithDetails: (details) => _canDropGame(details.data, date, time),
      onLeave: (data) {
        // Add haptic feedback when leaving a valid drop zone
        if (data != null && _canDropGame(data, date, time)) {
          HapticFeedback.selectionClick();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        final isValid = candidateData.isNotEmpty && 
                       candidateData.first != null && 
                       _canDropGame(candidateData.first!, date, time);
        final isEmpty = games.isEmpty;
        final hasConflicts = candidateData.isNotEmpty && !isValid;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasConflicts 
                ? Colors.red.withOpacity(0.15)
                : isHighlighted && isValid 
                  ? Colors.green.withOpacity(0.15)
                  : isEmpty 
                    ? Colors.grey.withOpacity(0.05)
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasConflicts 
                  ? Colors.red
                  : isHighlighted && isValid 
                    ? Colors.green
                    : isEmpty 
                      ? Colors.grey.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
              width: hasConflicts ? 3 : isHighlighted ? 2 : 1,
            ),
            boxShadow: [
              if (isHighlighted) ...[
                BoxShadow(
                  color: (isValid ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: hasConflicts ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ]
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time header with availability indicator
              Row(
                children: [
                  Icon(
                    hasConflicts ? Icons.error : isEmpty ? Icons.schedule_outlined : Icons.sports_soccer,
                    size: 16,
                    color: hasConflicts 
                        ? Colors.red 
                        : isEmpty 
                          ? Colors.grey[600] 
                          : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasConflicts 
                          ? Colors.red 
                          : isEmpty 
                            ? Colors.grey[600] 
                          : Colors.blue[700],
                    ),
                  ),
                  const Spacer(),
                  if (isEmpty && !hasConflicts) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isHighlighted && isValid 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isHighlighted && isValid 
                              ? Colors.green
                              : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isHighlighted && isValid ? 'Drop Here' : 'Available',
                        style: TextStyle(
                          fontSize: 10, 
                          color: isHighlighted && isValid ? Colors.green[800] : Colors.green,
                          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ] else if (hasConflicts) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.block, size: 12, color: Colors.red[800]),
                          const SizedBox(width: 4),
                          Text(
                            'CONFLICT',
                            style: TextStyle(
                              fontSize: 10, 
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              if (isEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: hasConflicts 
                        ? Colors.red.withOpacity(0.05)
                        : isHighlighted && isValid 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasConflicts 
                          ? Colors.red.withOpacity(0.5)
                          : isHighlighted && isValid 
                            ? Colors.green.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        hasConflicts 
                            ? Icons.block
                            : isHighlighted && isValid 
                              ? Icons.download
                              : Icons.add_circle_outline,
                        color: hasConflicts 
                            ? Colors.red
                            : isHighlighted && isValid 
                              ? Colors.green
                              : Colors.grey[500],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasConflicts 
                            ? 'Team Conflict!'
                            : isHighlighted && isValid 
                              ? 'Drop game here'
                              : 'Drop game here',
                        style: TextStyle(
                          color: hasConflicts 
                              ? Colors.red[700]
                              : isHighlighted && isValid 
                                ? Colors.green[700]
                                : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: hasConflicts ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                ...games.map((game) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildDraggableGameCard(game),
                )),
              ],
              
              // Show detailed conflict information when hovering
              if (hasConflicts) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Scheduling Conflict',
                            style: TextStyle(
                              color: Colors.red[800], 
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        candidateData.isNotEmpty && candidateData.first != null
                            ? '${_getDetailedConflictInfo(candidateData.first!, date, time, '')['type']}: ${_getDetailedConflictInfo(candidateData.first!, date, time, '')['message']}'
                            : 'One or more teams are already playing at this time',
                        style: TextStyle(color: Colors.red[700], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableGameCard(GameModel game) {
    // Use gray background for completed games, team gradient for others
    final bool isCompleted = game.status == GameStatus.completed;
    final borderColor = isCompleted ? Colors.grey.shade400 : Colors.blue;
    final backgroundColor = isCompleted ? Colors.grey.shade100 : Colors.white;
    
    // Don't make completed games draggable
    if (isCompleted) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: _buildCompactGameCard(game),
      );
    }
    
    return Draggable<GameModel>(
      data: game,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.drag_indicator, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Moving: ${game.displayName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_getTeamName(game.team1Id ?? '')} vs ${_getTeamName(game.team2Id ?? '')}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (game.scheduledDate != null && game.scheduledTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Current: ${_formatDate(game.scheduledDate!)} at ${game.scheduledTime}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.5), style: BorderStyle.solid),
        ),
        child: Opacity(
          opacity: 0.3,
          child: _buildCompactGameCard(game),
        ),
      ),
      onDragStarted: () {
        HapticFeedback.lightImpact();
      },
      onDragEnd: (details) {
        HapticFeedback.lightImpact();
      },
      onDragCompleted: () {
        HapticFeedback.mediumImpact();
      },
      onDraggableCanceled: (velocity, offset) {
        HapticFeedback.heavyImpact();
        // Show detailed guidance message instead of generic cancellation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Could not move ${game.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Possible reasons:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Dropped outside a valid time slot',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '• Team already playing at that time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '• Court already booked at that time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Try: Drop on a green-highlighted time slot or look for "Available" cells',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.9),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      dragAnchorStrategy: (draggable, context, position) {
        return const Offset(160, 50); // Center of the feedback widget
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: _buildCompactGameCard(game),
      ),
    );
  }

  // New compact game card for grid view
  Widget _buildCompactGameCard(GameModel game) {
    // Use gray background for completed games, team gradient for others
    final bool isCompleted = game.status == GameStatus.completed;
    final gradient = isCompleted ? null : _createTeamGradient(game);
    final borderColor = isCompleted ? Colors.grey.shade300 : _getTeamBorderColor(game);
    final backgroundColor = isCompleted ? Colors.grey.shade100 : null;
    
    return Container(
      width: double.infinity,
      height: 85, // Increased from 55 to 85
      padding: const EdgeInsets.all(8), // Increased padding
      decoration: BoxDecoration(
        gradient: gradient,
        color: backgroundColor ?? (gradient == null ? Colors.white : null),
        borderRadius: BorderRadius.circular(8), // Larger radius
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Game name - make it bigger
          Text(
            game.displayName,
            style: const TextStyle(
              fontSize: 12, // Increased from 8 to 12
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (game.hasTeams) ...[
            const SizedBox(height: 4), // Increased spacing
            Row(
              children: [
                // Team 1 color indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getTeamColor(game.team1Id, defaultColor: Colors.blue),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_getTeamName(game.team1Id ?? '')} vs ${_getTeamName(game.team2Id ?? '')}',
                    style: const TextStyle(
                      fontSize: 10, // Increased from 7 to 10
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                // Team 2 color indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getTeamColor(game.team2Id, defaultColor: Colors.green),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          // Time indicator with enhanced styling
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12, // Increased from 8 to 12
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  game.scheduledTime ?? 'No time',
                  style: TextStyle(
                    fontSize: 9, // Increased from 6 to 9
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canDropGame(GameModel game, String targetDate, String targetTime) {
    try {
      // Parse target date
      final dateParts = targetDate.split('/');
      if (dateParts.length != 3) {
        return false;
      }
      
      final targetDateTime = DateTime(
        int.parse(dateParts[2]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[0]), // day
      );

      // Normalize target time format
      final normalizedTargetTime = _normalizeTimeFormat(targetTime);

      // Check if this is the same slot the game is already in
      if (game.scheduledDate != null && game.scheduledTime != null) {
        final isSameDate = _isSameDate(game.scheduledDate!, targetDateTime);
        final isSameTime = _normalizeTimeFormat(game.scheduledTime!) == normalizedTargetTime;
        if (isSameDate && isSameTime) {
          return true; // Allow dropping in the same slot (no-op)
        }
      }

      // Check if there are conflicting games at this time slot
      final conflictingGames = _allGames.where((otherGame) {
        if (otherGame.id == game.id) return false; // Don't check against itself
        
        if (otherGame.scheduledDate != null && otherGame.scheduledTime != null) {
          final isSameDate = _isSameDate(otherGame.scheduledDate!, targetDateTime);
          final isSameTime = _normalizeTimeFormat(otherGame.scheduledTime!) == normalizedTargetTime;
          
          if (isSameDate && isSameTime) {
            // Check if any team conflicts
            final hasTeamConflict = (otherGame.team1Id == game.team1Id || 
                    otherGame.team1Id == game.team2Id ||
                    otherGame.team2Id == game.team1Id || 
                    otherGame.team2Id == game.team2Id);
            
            return hasTeamConflict;
          }
        }
        return false;
      }).toList();

      return conflictingGames.isEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleGameDrop(GameModel game, String targetDate, String targetTime) async {
    // Normalize the target time format
    final normalizedTime = _normalizeTimeFormat(targetTime);
    
    if (!_canDropGame(game, targetDate, normalizedTime)) {
      final conflictInfo = _getDetailedConflictInfo(game, targetDate, normalizedTime, '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cannot move ${game.displayName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${conflictInfo['type']}: ${conflictInfo['message']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                if (conflictInfo['details'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    conflictInfo['details'].toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
                if (conflictInfo['suggestion'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Suggestion: ${conflictInfo['suggestion'].toString()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6), // Longer duration for detailed message
          ),
        );
      }
      return;
    }

    // Parse target date
    final dateParts = targetDate.split('/');
    final targetDateTime = DateTime(
      int.parse(dateParts[2]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[0]), // day
    );

    // Check if this is the same slot (no-op)
    if (game.scheduledDate != null && game.scheduledTime != null) {
      final isSameDate = _isSameDate(game.scheduledDate!, targetDateTime);
      final isSameTime = _normalizeTimeFormat(game.scheduledTime!) == normalizedTime;
      if (isSameDate && isSameTime) {
        return;
      }
    }

    try {
      // Update the game in database with normalized time
      await _repository.updateGame(
        gameId: game.id,
        scheduledDate: targetDateTime,
        scheduledTime: normalizedTime,
      );

      // Refresh the games list
      await _loadGames();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Moved ${game.displayName} to $targetDate at $normalizedTime',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moving game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGameCard(GameModel game) {
    // Use gray background for completed games, team gradient for others
    final bool isCompleted = game.status == GameStatus.completed;
    final gradient = isCompleted ? null : _createTeamGradient(game);
    final borderColor = isCompleted ? Colors.grey.shade300 : _getTeamBorderColor(game);
    final backgroundColor = isCompleted ? Colors.grey.shade100 : null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with game name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      game.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(game.status),
                ],
              ),
              const SizedBox(height: 12),
              
              // Teams section with color indicators and winner highlighting
              if (game.hasTeams) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      // Team 1
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isWinner(game, game.team1Id) 
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: _isWinner(game, game.team1Id)
                                ? Border.all(color: Colors.amber, width: 2)
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getTeamColor(game.team1Id, defaultColor: Colors.blue),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_isWinner(game, game.team1Id))
                                const Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              if (_isWinner(game, game.team1Id))
                                const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _teamMap[game.team1Id]?.name ?? 'Team 1',
                                  style: TextStyle(
                                    fontWeight: _isWinner(game, game.team1Id) 
                                        ? FontWeight.bold 
                                        : FontWeight.w600,
                                    fontSize: 16,
                                    color: _isWinner(game, game.team1Id) 
                                        ? Colors.amber.shade800 
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (game.hasResults && game.team1Score != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _isWinner(game, game.team1Id) 
                                        ? Colors.amber.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${game.team1Score}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _isWinner(game, game.team1Id) 
                                          ? Colors.amber.shade800
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // VS indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      
                      // Team 2
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isWinner(game, game.team2Id) 
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: _isWinner(game, game.team2Id)
                                ? Border.all(color: Colors.amber, width: 2)
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (game.hasResults && game.team2Score != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _isWinner(game, game.team2Id) 
                                        ? Colors.amber.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${game.team2Score}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _isWinner(game, game.team2Id) 
                                          ? Colors.amber.shade800
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              if (game.hasResults && game.team2Score != null)
                                const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _teamMap[game.team2Id]?.name ?? 'Team 2',
                                  style: TextStyle(
                                    fontWeight: _isWinner(game, game.team2Id) 
                                        ? FontWeight.bold 
                                        : FontWeight.w600,
                                    fontSize: 16,
                                    color: _isWinner(game, game.team2Id) 
                                        ? Colors.amber.shade800 
                                        : Colors.black87,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                              if (_isWinner(game, game.team2Id))
                                const SizedBox(width: 4),
                              if (_isWinner(game, game.team2Id))
                                const Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              const SizedBox(width: 8),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getTeamColor(game.team2Id, defaultColor: Colors.green),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (game.hasResults) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          game.resultSummary!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Text('Teams not assigned'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Schedule info
              Row(
                children: [
                  if (game.scheduledDateTime != null) ...[
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        game.scheduledDateTime!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Not scheduled',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ],
              ),
              
              // Resource/Court info
              if (game.resourceId != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _resourceMap[game.resourceId]?.name ?? 'Unknown Resource',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              
              // Action buttons
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    onPressed: game.canEdit ? () => _editGame(game) : null,
                  ),
                  if (game.status == GameStatus.scheduled) ...[
                    _buildActionButton(
                      icon: Icons.play_arrow,
                      label: 'Start',
                      onPressed: game.canStart ? () => _startGame(game) : null,
                    ),
                  ] else if (game.status == GameStatus.inProgress) ...[
                    _buildActionButton(
                      icon: Icons.score,
                      label: 'Score',
                      onPressed: () => _showScoreDialog(game),
                    ),
                  ] else if (game.status == GameStatus.completed) ...[
                    _buildActionButton(
                      icon: Icons.edit_note,
                      label: 'Edit Score',
                      onPressed: () => _showScoreDialog(game),
                    ),
                  ],
                  _buildActionButton(
                    icon: Icons.visibility,
                    label: 'View',
                    onPressed: () => _viewGame(game),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(GameStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case GameStatus.scheduled:
        color = Colors.blue;
        icon = Icons.schedule;
        break;
      case GameStatus.inProgress:
        color = Colors.green;
        icon = Icons.play_arrow;
        break;
      case GameStatus.completed:
        color = Colors.purple;
        icon = Icons.check_circle;
        break;
      case GameStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case GameStatus.postponed:
        color = Colors.orange;
        icon = Icons.pause;
        break;
      case GameStatus.forfeit:
        color = Colors.red;
        icon = Icons.flag;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: onPressed != null 
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onPressed != null ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  // Enhanced conflict detection with detailed explanations
  Map<String, dynamic> _getDetailedConflictInfo(GameModel game, String targetDate, String targetTime, String resourceId) {
    try {
      final dateParts = targetDate.split('/');
      if (dateParts.length != 3) {
        return {
          'hasConflict': true,
          'type': 'Invalid Date',
          'message': 'Invalid date format provided'
        };
      }
      
      final targetDateTime = DateTime(
        int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]),
      );
      final normalizedTargetTime = _normalizeTimeFormat(targetTime);
      
      // Check for resource conflicts first (court double-booking)
      final resourceConflictGame = _allGames.where(
        (otherGame) => 
          otherGame.id != game.id &&
          otherGame.scheduledDate != null &&
          otherGame.scheduledTime != null &&
          otherGame.resourceId != null &&
          _isSameDate(otherGame.scheduledDate!, targetDateTime) &&
          _normalizeTimeFormat(otherGame.scheduledTime!) == normalizedTargetTime &&
          otherGame.resourceId == resourceId,
      ).firstOrNull;
      
      if (resourceConflictGame != null) {
        final resourceName = _resourceMap[resourceId]?.name ?? 'this court';
        return {
          'hasConflict': true,
          'type': 'Court Double-Booking',
          'message': '$resourceName is already booked at $normalizedTargetTime',
          'details': 'Conflicting game: ${resourceConflictGame.displayName} (${_getTeamName(resourceConflictGame.team1Id ?? '')} vs ${_getTeamName(resourceConflictGame.team2Id ?? '')})',
          'suggestion': 'Try a different time slot or court'
        };
      }
      
      // Check for team conflicts (teams playing multiple games simultaneously)
      final conflictingTeams = <String>[];
      final conflictingGames = <GameModel>[];
      
      for (final otherGame in _allGames) {
        if (otherGame.id == game.id) continue;
        
        if (otherGame.scheduledDate != null && otherGame.scheduledTime != null) {
          final isSameDate = _isSameDate(otherGame.scheduledDate!, targetDateTime);
          final isSameTime = _normalizeTimeFormat(otherGame.scheduledTime!) == normalizedTargetTime;
          
          if (isSameDate && isSameTime) {
            bool hasTeamConflict = false;
            
            if (otherGame.team1Id == game.team1Id || otherGame.team1Id == game.team2Id) {
              final teamName = _getTeamName(otherGame.team1Id ?? '');
              if (!conflictingTeams.contains(teamName)) {
                conflictingTeams.add(teamName);
                hasTeamConflict = true;
              }
            }
            if (otherGame.team2Id == game.team1Id || otherGame.team2Id == game.team2Id) {
              final teamName = _getTeamName(otherGame.team2Id ?? '');
              if (!conflictingTeams.contains(teamName)) {
                conflictingTeams.add(teamName);
                hasTeamConflict = true;
              }
            }
            
            if (hasTeamConflict) {
              conflictingGames.add(otherGame);
            }
          }
        }
      }
      
      if (conflictingTeams.isNotEmpty) {
        final teamList = conflictingTeams.length == 1 
            ? conflictingTeams.first
            : '${conflictingTeams.take(conflictingTeams.length - 1).join(', ')} and ${conflictingTeams.last}';
            
        final gameList = conflictingGames.map((g) {
          final court = _resourceMap[g.resourceId]?.name ?? 'Unknown Court';
          return '${g.displayName} on $court';
        }).join(', ');
        
        return {
          'hasConflict': true,
          'type': 'Team Schedule Conflict',
          'message': '$teamList ${conflictingTeams.length == 1 ? 'is' : 'are'} already scheduled at $normalizedTargetTime',
          'details': 'Conflicting game${conflictingGames.length > 1 ? 's' : ''}: $gameList',
          'suggestion': 'Choose a different time when ${conflictingTeams.length == 1 ? 'this team is' : 'these teams are'} available'
        };
      }
      
      return {
        'hasConflict': false,
        'type': 'No Conflict',
        'message': 'Move is allowed'
      };
    } catch (e) {
      return {
        'hasConflict': true,
        'type': 'System Error',
        'message': 'Error checking for conflicts: $e'
      };
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _getTeamName(String teamId) {
    return _teamMap[teamId]?.name ?? 'Unknown Team';
  }

  // Placeholder methods
  void _showGenerateScheduleDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GenerateScheduleDialog(
        tournamentId: widget.tournamentId,
        onScheduleGenerated: (games) {
          _loadGames();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully generated ${games.length} games!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() {
            _tabController.animateTo(0);
          });
        },
      ),
    );
  }
  
  void _showDeleteAllGamesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete All Games'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete all ${_allGames.length} games?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('This action will:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.delete_forever, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text('Delete ${_allGames.length} games permanently'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_send, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text('Remove all scheduled times and assignments'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Text('Clear all game statistics and results'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAllGames();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_forever, size: 16),
                const SizedBox(width: 4),
                const Text('Delete All'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllGames() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Deleting all games...'),
              ],
            ),
            duration: Duration(seconds: 30), // Long duration
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Delete all games from the database
      final gameIds = _allGames.map((game) => game.id).toList();
      
      for (final gameId in gameIds) {
        await _repository.deleteGame(gameId);
      }

      // Refresh the games list
      await _loadGames();

      if (mounted) {
        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Successfully deleted ${gameIds.length} games'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Failed to delete games',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Error: $e',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.download, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Export Tournament Data'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose what to export and the format:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              
              // Export options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Text('Tournament Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Export ${_hasActiveFilters() ? _filteredAllGames.length : _allGames.length} games with dates, times, teams, and scores'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildExportButton('CSV', ExportFormat.csv, _exportSchedule, Colors.green),
                          _buildExportButton('JSON', ExportFormat.json, _exportSchedule, Colors.blue),
                          _buildExportButton('HTML', ExportFormat.html, _exportSchedule, Colors.orange),
                          _buildExportButton('TXT', ExportFormat.txt, _exportSchedule, Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          const Text('Tournament Standings', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Export current standings with points, wins, losses, and statistics'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildExportButton('CSV', ExportFormat.csv, _exportStandings, Colors.green),
                          _buildExportButton('JSON', ExportFormat.json, _exportStandings, Colors.blue),
                          _buildExportButton('HTML', ExportFormat.html, _exportStandings, Colors.orange),
                          _buildExportButton('TXT', ExportFormat.txt, _exportStandings, Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_zip, color: Colors.purple, size: 20),
                          const SizedBox(width: 8),
                          const Text('Complete Tournament', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Export everything: schedule, standings, teams, and resources'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildExportButton('JSON', ExportFormat.json, _exportComplete, Colors.blue),
                          _buildExportButton('HTML', ExportFormat.html, _exportComplete, Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Files will be downloaded automatically to your browser\'s download folder.',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(String label, ExportFormat format, Function(ExportFormat) onPressed, Color color) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop(); // Close dialog first
        onPressed(format);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(60, 32),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _exportSchedule(ExportFormat format) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Exporting schedule as ${format.name.toUpperCase()}...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 5),
        ),
      );

      final games = _hasActiveFilters() ? _filteredAllGames : _allGames;
      
      await ExportService.exportSchedule(
        tournamentName: widget.tournamentName,
        games: games,
        teamMap: _teamMap,
        resourceMap: _resourceMap,
        format: format,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Schedule exported successfully as ${format.name.toUpperCase()}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportStandings(ExportFormat format) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Exporting standings as ${format.name.toUpperCase()}...'),
            ],
          ),
          backgroundColor: Colors.amber,
          duration: const Duration(seconds: 5),
        ),
      );

      final standings = TournamentStandingsService.calculateStandings(
        tournamentId: widget.tournamentId,
        format: TournamentFormat.roundRobin,
        games: _allGames,
        teams: _hasActiveFilters() ? _filteredTeams : _teams,
        phase: 'tournament',
      );
      
      await ExportService.exportStandings(
        tournamentName: widget.tournamentName,
        standings: standings,
        format: format,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Standings exported successfully as ${format.name.toUpperCase()}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export standings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportComplete(ExportFormat format) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Exporting complete tournament as ${format.name.toUpperCase()}...'),
            ],
          ),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 10),
        ),
      );

      final standings = TournamentStandingsService.calculateStandings(
        tournamentId: widget.tournamentId,
        format: TournamentFormat.roundRobin,
        games: _allGames,
        teams: _teams,
        phase: 'tournament',
      );
      
      await ExportService.exportTournamentComplete(
        tournamentName: widget.tournamentName,
        games: _allGames,
        teamMap: _teamMap,
        resourceMap: _resourceMap,
        standings: standings,
        format: format,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Complete tournament exported successfully as ${format.name.toUpperCase()}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export tournament: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHelpDialog() {}
  void _showGameOptions(GameModel game) {}
  void _showCompleteGameDialog(GameModel game) {}

  void _showScoreDialog(GameModel game) {
    final team1ScoreController = TextEditingController(
      text: game.team1Score?.toString() ?? '',
    );
    final team2ScoreController = TextEditingController(
      text: game.team2Score?.toString() ?? '',
    );
    final notesController = TextEditingController(text: game.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Record Score - ${game.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Teams and current status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getTeamColor(game.team1Id, defaultColor: Colors.blue),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _teamMap[game.team1Id]?.name ?? 'Team 1',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            _teamMap[game.team2Id]?.name ?? 'Team 2',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getTeamColor(game.team2Id, defaultColor: Colors.green),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          game.status == GameStatus.completed 
                            ? Icons.check_circle 
                            : Icons.play_arrow,
                          color: game.status == GameStatus.completed 
                            ? Colors.green 
                            : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          game.statusDisplayName,
                          style: TextStyle(
                            color: game.status == GameStatus.completed 
                              ? Colors.green 
                              : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Score input section
              Row(
                children: [
                  // Team 1 score
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _teamMap[game.team1Id]?.name ?? 'Team 1',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: team1ScoreController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, 
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // VS divider
                  const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Team 2 score
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _teamMap[game.team2Id]?.name ?? 'Team 2',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: team2ScoreController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, 
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Notes section
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any game notes...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (game.status == GameStatus.inProgress) ...[
            ElevatedButton(
              onPressed: () => _updateScore(
                game,
                team1ScoreController,
                team2ScoreController,
                notesController,
                false, // Don't complete, just update
              ),
              child: const Text('Update Score'),
            ),
            ElevatedButton(
              onPressed: () => _updateScore(
                game,
                team1ScoreController,
                team2ScoreController,
                notesController,
                true, // Complete the game
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete Game'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () => _updateScore(
                game,
                team1ScoreController,
                team2ScoreController,
                notesController,
                true, // Complete the game
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete Game'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateScore(
    GameModel game,
    TextEditingController team1ScoreController,
    TextEditingController team2ScoreController,
    TextEditingController notesController,
    bool completeGame,
  ) async {
    try {
      // Parse scores
      final team1Score = int.tryParse(team1ScoreController.text) ?? 0;
      final team2Score = int.tryParse(team2ScoreController.text) ?? 0;
      final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();

      // Determine winner if completing the game
      String? winnerId;
      if (completeGame && team1Score != team2Score) {
        winnerId = team1Score > team2Score ? game.team1Id : game.team2Id;
      }

      // Close the dialog first
      Navigator.of(context).pop();

      if (completeGame) {
        // Complete the game with final scores
        await _repository.completeGame(
          gameId: game.id,
          team1Score: team1Score,
          team2Score: team2Score,
          winnerId: winnerId,
          refereeNotes: notes,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Game completed: ${_teamMap[game.team1Id]?.name ?? 'Team 1'} $team1Score - $team2Score ${_teamMap[game.team2Id]?.name ?? 'Team 2'}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update score without completing - use direct database update
        await _updateScoreInDatabase(
          gameId: game.id,
          team1Score: team1Score,
          team2Score: team2Score,
          winnerId: winnerId,
          notes: notes,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Score updated: $team1Score - $team2Score'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }

      // Refresh games list
      await _loadGames();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating score: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 15), // Extended duration to read/copy error
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Copy',
              textColor: Colors.white,
              onPressed: () {
                // Copy error to clipboard if available
                print('Error details: $e');
              },
            ),
          ),
        );
      }
    }
  }

  /// Helper method to check if a team is the winner of a game
  bool _isWinner(GameModel game, String? teamId) {
    // Only show winner for completed games with a winner
    if (game.status != GameStatus.completed || 
        game.winnerId == null || 
        teamId == null) {
      return false;
    }
    return game.winnerId == teamId;
  }

  Future<void> _updateScoreInDatabase({
    required String gameId,
    required int team1Score,
    required int team2Score,
    String? winnerId,
    String? notes,
  }) async {
    // Create a temporary GameRepository client to access Supabase directly
    final supabase = Supabase.instance.client;
    
    final updateData = <String, dynamic>{
      'team1_score': team1Score,
      'team2_score': team2Score,
      'winner_id': winnerId,
    };
    
    if (notes != null) {
      updateData['notes'] = notes;
    }
    
    await supabase
        .from('games')
        .update(updateData)
        .eq('id', gameId);
  }

  Future<void> _startGame(GameModel game) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Start Game'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you ready to start this game?'),
              const SizedBox(height: 12),
              Text(
                '${_teamMap[game.team1Id]?.name ?? 'Team 1'} vs ${_teamMap[game.team2Id]?.name ?? 'Team 2'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (game.scheduledDateTime != null) ...[
                const SizedBox(height: 8),
                Text('Scheduled: ${game.scheduledDateTime}'),
              ],
              if (game.resourceId != null) ...[
                const SizedBox(height: 8),
                Text('Court: ${_resourceMap[game.resourceId]?.name ?? 'Unknown'}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start Game'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Start the game using repository
        await _repository.startGame(game.id);
        
        // Refresh games list
        await _loadGames();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Game started: ${game.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Automatically open score recording dialog
          _showScoreDialog(game.copyWith(status: GameStatus.inProgress));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting game: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 15), // Extended duration to read/copy error
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Copy',
              textColor: Colors.white,
              onPressed: () {
                // Copy error to clipboard if available
                print('Error details: $e');
              },
            ),
          ),
        );
      }
    }
  }
  
  // Example of enhanced conflict messaging
  void _showConflictExample(GameModel game) {
    final conflictInfo = _getDetailedConflictInfo(game, '30/8/2025', '06:00', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cannot move ${game.displayName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${conflictInfo['type']}: ${conflictInfo['message']}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            if (conflictInfo['details'] != null) ...[
              const SizedBox(height: 2),
              Text(
                conflictInfo['details'].toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildGridView(List<GameModel> games) {
    // Enhanced grid view with drag and drop and conflict detection
    if (games.isEmpty) {
      return _buildEmptyState('No games scheduled yet');
    }

    // Dynamically detect the time interval based on existing games
    final timeSlots = <String>[];
    int detectedIntervalMinutes = 30; // Default fallback
    
    // Analyze existing games to detect the interval pattern
    if (games.isNotEmpty) {
      final gameTimes = games
          .where((g) => g.scheduledTime != null)
          .map((g) => _normalizeTimeFormat(g.scheduledTime!))
          .toSet()
          .toList()
          ..sort();
      
      if (gameTimes.length >= 2) {
        // Calculate intervals between consecutive game times
        final intervals = <int>[];
        for (int i = 1; i < gameTimes.length; i++) {
          final prev = _parseTimeString(gameTimes[i - 1]);
          final curr = _parseTimeString(gameTimes[i]);
          if (prev != null && curr != null) {
            final diffMinutes = curr.difference(prev).inMinutes;
            if (diffMinutes > 0 && diffMinutes <= 120) { // Reasonable game interval
              intervals.add(diffMinutes);
            }
          }
        }
        
        // Use the most common interval, or fallback to estimated duration
        if (intervals.isNotEmpty) {
          intervals.sort();
          detectedIntervalMinutes = intervals[intervals.length ~/ 2]; // Median
        } else {
          // Fallback to game estimated duration if available
          final durations = games
              .map((g) => g.estimatedDuration)
              .where((d) => d > 0)
              .toList();
          if (durations.isNotEmpty) {
            detectedIntervalMinutes = durations.first;
          }
        }
      }
    }
    
    // Generate time slots based on detected interval
    const int startHour = 6;
    const int endHour = 23;
    
    DateTime currentTime = DateTime(2024, 1, 1, startHour, 0);
    final endTime = DateTime(2024, 1, 1, endHour, 0);
    
    while (currentTime.isBefore(endTime) || currentTime.isAtSameMomentAs(endTime)) {
      final timeString = '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
      timeSlots.add(timeString);
      currentTime = currentTime.add(Duration(minutes: detectedIntervalMinutes));
    }
    
    // Add any existing game times that don't fit the detected pattern
    final actualTimes = games
        .where((g) => g.scheduledTime != null)
        .map((g) => _normalizeTimeFormat(g.scheduledTime!))
        .toSet()
        .where((time) => !timeSlots.contains(time))
        .toList();
    
    timeSlots.addAll(actualTimes);
    timeSlots.sort();

    // Get all unique dates
    final dates = games
        .where((g) => g.scheduledDate != null)
        .map((g) => g.scheduledDate!)
        .toSet()
        .toList()
        ..sort();

    if (dates.isEmpty) {
      return _buildEmptyState('No games with dates scheduled');
    }

    return Column(
      children: [
        // Compact instructions for drag and drop
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator, color: Colors.blue, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Full Screen Grid: ${timeSlots.length} time slots (${detectedIntervalMinutes}min intervals detected). Drag games between courts.',
                  style: TextStyle(color: Colors.blue[800], fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        
        // Full screen grid
        Expanded(
          child: ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) => _buildFullScreenDateGrid(dates[index], timeSlots, games),
          ),
        ),
      ],
    );
  }

  // Helper method to parse time string to DateTime for interval calculation
  DateTime? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(2024, 1, 1, hour, minute);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  // Helper method to normalize time formats
  String _normalizeTimeFormat(String time) {
    // Remove seconds if present (e.g., "06:00:00" -> "06:00")
    if (time.contains(':') && time.split(':').length > 2) {
      final parts = time.split(':');
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  Widget _buildFullScreenDateGrid(DateTime date, List<String> timeSlots, List<GameModel> allGames) {
    final dateString = _formatDate(date);
    final dayGames = allGames.where((g) => 
      g.scheduledDate != null && _isSameDate(g.scheduledDate!, date)
    ).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact date header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  dateString,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Full screen data table
          SizedBox(
            height: timeSlots.length * 90 + 45, // Increased height for bigger cells
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 8, // Increased spacing
                horizontalMargin: 12,
                headingRowHeight: 45, // Increased header height
                dataRowHeight: 90, // Increased from 55 to 90
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13, // Increased header text size
                ),
                columns: [
                  const DataColumn(
                    label: SizedBox(
                      width: 80, // Increased time column width
                      child: Text('Time'),
                    ),
                  ),
                  ..._resources.map((resource) => DataColumn(
                    label: SizedBox(
                      width: 280, // Increased court column width significantly
                      child: Text(
                        resource.name,
                        style: const TextStyle(fontSize: 13), // Increased text size
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )),
                ],
                rows: timeSlots.map((timeSlot) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            timeSlot,
                            style: const TextStyle(
                              fontSize: 12, // Increased from 10 to 12
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      ..._resources.map((resource) {
                        final game = dayGames.where((g) => 
                          _normalizeTimeFormat(g.scheduledTime ?? '') == timeSlot && g.resourceId == resource.id
                        ).firstOrNull;
                        
                        return DataCell(
                          _buildCompactGridCell(dateString, timeSlot, resource.id, game),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactGridCell(String date, String time, String resourceId, GameModel? existingGame) {
    return DragTarget<GameModel>(
      onAcceptWithDetails: (details) => _handleGameDropToResource(details.data, date, time, resourceId),
      onWillAcceptWithDetails: (details) => _canDropGameToResource(details.data, date, time, resourceId),
      onLeave: (data) {
        if (data != null && _canDropGameToResource(data, date, time, resourceId)) {
          HapticFeedback.selectionClick();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        final isValid = candidateData.isNotEmpty && 
                       candidateData.first != null && 
                       _canDropGameToResource(candidateData.first!, date, time, resourceId);
        final hasConflicts = candidateData.isNotEmpty && !isValid;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280, // Reduced width to fit more courts
          height: 90,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: hasConflicts 
                ? Colors.red.withOpacity(0.15)
                : isHighlighted && isValid 
                  ? Colors.green.withOpacity(0.15)
                  : existingGame != null 
                    ? Colors.blue.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.02),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: hasConflicts 
                  ? Colors.red
                  : isHighlighted && isValid 
                    ? Colors.green
                    : existingGame != null 
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
              width: hasConflicts ? 2 : isHighlighted ? 2 : 1,
            ),
            boxShadow: [
              if (isHighlighted) ...[
                BoxShadow(
                  color: (isValid ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: hasConflicts ? 6 : 4,
                  offset: const Offset(0, 1),
                ),
              ]
            ],
          ),
          child: existingGame != null 
              ? _buildGridDraggableGameCard(existingGame)
              : Container(
                  decoration: BoxDecoration(
                    color: hasConflicts 
                        ? Colors.red.withOpacity(0.1)
                        : isHighlighted && isValid 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isHighlighted ? Border.all(
                      color: isValid ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                      style: BorderStyle.solid,
                    ) : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasConflicts 
                              ? Icons.block
                              : isHighlighted && isValid 
                                ? Icons.download
                                : Icons.add_circle_outline,
                          color: hasConflicts 
                              ? Colors.red
                              : isHighlighted && isValid 
                                ? Colors.green
                              : Colors.grey[400],
                          size: 24, // Increased from 16 to 24
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasConflicts 
                              ? 'Conflict'
                              : isHighlighted && isValid 
                                ? 'Drop here'
                                : 'Available',
                          style: TextStyle(
                            color: hasConflicts 
                                ? Colors.red[700]
                                : isHighlighted && isValid 
                                  ? Colors.green[700]
                                  : Colors.grey[500],
                            fontSize: 12, // Increased from 8 to 12
                            fontWeight: hasConflicts ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first game to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showGenerateScheduleDialog,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Generate Schedule'),
          ),
        ],
      ),
    );
  }

  // Grid-specific draggable game card
  Widget _buildGridDraggableGameCard(GameModel game) {
    // Use gray background for completed games, team gradient for others
    final bool isCompleted = game.status == GameStatus.completed;
    final borderColor = isCompleted ? Colors.grey.shade400 : Colors.blue;
    final backgroundColor = isCompleted ? Colors.grey.shade100 : Colors.white;
    
    // Don't make completed games draggable
    if (isCompleted) {
      return _buildCompactGameCard(game);
    }
    
    return Draggable<GameModel>(
      data: game,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280, // Increased to match cell width
          height: 90, // Increased to match cell height
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12), // Increased padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Moving: ${game.displayName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // Increased from 10 to 12
                    color: Colors.blue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getTeamName(game.team1Id ?? '')} vs ${_getTeamName(game.team2Id ?? '')}',
                  style: const TextStyle(fontSize: 10), // Increased from 8 to 10
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blue.withOpacity(0.5), style: BorderStyle.solid),
        ),
        child: Opacity(
          opacity: 0.3,
          child: _buildCompactGameCard(game),
        ),
      ),
      onDragStarted: () {
        HapticFeedback.lightImpact();
      },
      onDragEnd: (details) {
        HapticFeedback.lightImpact();
      },
      onDragCompleted: () {
        HapticFeedback.mediumImpact();
      },
      onDraggableCanceled: (velocity, offset) {
        HapticFeedback.heavyImpact();
        // Show detailed guidance message instead of generic cancellation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Could not move ${game.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Possible reasons:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Dropped outside a valid time slot',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '• Team already playing at that time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '• Court already booked at that time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Try: Drop on a green-highlighted time slot or look for "Available" cells',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.9),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      dragAnchorStrategy: (draggable, context, position) {
        return const Offset(140, 45); // Center of the feedback widget
      },
      child: _buildCompactGameCard(game),
    );
  }

  bool _canDropGameToResource(GameModel game, String targetDate, String targetTime, String resourceId) {
    try {
      // Parse target date
      final dateParts = targetDate.split('/');
      if (dateParts.length != 3) {
        return false;
      }
      
      final targetDateTime = DateTime(
        int.parse(dateParts[2]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[0]), // day
      );

      // Normalize target time format
      final normalizedTargetTime = _normalizeTimeFormat(targetTime);

      // Check if this is the same slot the game is already in
      if (game.scheduledDate != null && game.scheduledTime != null && game.resourceId != null) {
        final isSameDate = _isSameDate(game.scheduledDate!, targetDateTime);
        final isSameTime = _normalizeTimeFormat(game.scheduledTime!) == normalizedTargetTime;
        final isSameResource = game.resourceId == resourceId;
        if (isSameDate && isSameTime && isSameResource) {
          return true; // Allow dropping in the same slot (no-op)
        }
      }

      // Check for resource conflicts (only one game per resource per time slot)
      final resourceConflict = _allGames.any((otherGame) => 
        otherGame.id != game.id &&
        otherGame.scheduledDate != null &&
        otherGame.scheduledTime != null &&
        otherGame.resourceId != null &&
        _isSameDate(otherGame.scheduledDate!, targetDateTime) &&
        _normalizeTimeFormat(otherGame.scheduledTime!) == normalizedTargetTime &&
        otherGame.resourceId == resourceId
      );

      if (resourceConflict) {
        return false;
      }

      // Check for team conflicts (teams can't play in multiple games at the same time)
      final teamConflict = _allGames.any((otherGame) => 
        otherGame.id != game.id &&
        otherGame.scheduledDate != null &&
        otherGame.scheduledTime != null &&
        _isSameDate(otherGame.scheduledDate!, targetDateTime) &&
        _normalizeTimeFormat(otherGame.scheduledTime!) == normalizedTargetTime &&
        (otherGame.team1Id == game.team1Id || 
         otherGame.team1Id == game.team2Id ||
         otherGame.team2Id == game.team1Id || 
         otherGame.team2Id == game.team2Id)
      );

      return !teamConflict;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleGameDropToResource(GameModel game, String targetDate, String targetTime, String resourceId) async {
    // Normalize the target time format
    final normalizedTime = _normalizeTimeFormat(targetTime);
    
    if (!_canDropGameToResource(game, targetDate, normalizedTime, resourceId)) {
      final conflictInfo = _getDetailedConflictInfo(game, targetDate, normalizedTime, resourceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cannot move ${game.displayName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${conflictInfo['type']}: ${conflictInfo['message']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                if (conflictInfo['details'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    conflictInfo['details'].toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
                if (conflictInfo['suggestion'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Suggestion: ${conflictInfo['suggestion'].toString()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6), // Longer duration for detailed message
          ),
        );
      }
      return;
    }

    // Parse target date
    final dateParts = targetDate.split('/');
    final targetDateTime = DateTime(
      int.parse(dateParts[2]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[0]), // day
    );

    // Check if this is the same slot (no-op)
    if (game.scheduledDate != null && game.scheduledTime != null && game.resourceId != null) {
      final isSameDate = _isSameDate(game.scheduledDate!, targetDateTime);
      final isSameTime = _normalizeTimeFormat(game.scheduledTime!) == normalizedTime;
      final isSameResource = game.resourceId == resourceId;
      if (isSameDate && isSameTime && isSameResource) {
        return;
      }
    }

    try {
      // Update the game in database with normalized time and new resource
      await _repository.updateGame(
        gameId: game.id,
        scheduledDate: targetDateTime,
        scheduledTime: normalizedTime,
        resourceId: resourceId,
      );

      // Refresh the games list
      await _loadGames();

      final resourceName = _resourceMap[resourceId]?.name ?? 'Resource';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Moved ${game.displayName} to $targetDate at $normalizedTime ($resourceName)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moving game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper function to create gradient between team colors
  Gradient? _createTeamGradient(GameModel game) {
    if (!game.hasTeams) return null;
    
    final team1 = _teamMap[game.team1Id];
    final team2 = _teamMap[game.team2Id];
    
    final color1 = team1?.color ?? Colors.blue.shade300;
    final color2 = team2?.color ?? Colors.green.shade300;
    
    return LinearGradient(
      colors: [color1.withOpacity(0.3), color2.withOpacity(0.3)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: const [0.0, 1.0],
    );
  }

  // Helper function to get a single team color or default
  Color _getTeamColor(String? teamId, {Color? defaultColor}) {
    if (teamId == null) return defaultColor ?? Colors.grey.shade300;
    final team = _teamMap[teamId];
    return team?.color ?? defaultColor ?? Colors.grey.shade300;
  }

  // Helper function to get border color for teams
  Color _getTeamBorderColor(GameModel game) {
    if (!game.hasTeams) return Colors.grey.withOpacity(0.3);
    
    final team1 = _teamMap[game.team1Id];
    final team2 = _teamMap[game.team2Id];
    
    if (team1?.color != null || team2?.color != null) {
      return (team1?.color ?? team2?.color ?? Colors.grey).withOpacity(0.6);
    }
    
    return Colors.grey.withOpacity(0.3);
  }

  void _editGame(GameModel game) {
    // TODO: Implement edit game functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit game functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewGame(GameModel game) {
    // Show detailed game information dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(game.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (game.hasTeams) ...[
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getTeamColor(game.team1Id, defaultColor: Colors.blue),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_teamMap[game.team1Id]?.name ?? 'Team 1'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getTeamColor(game.team2Id, defaultColor: Colors.green),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_teamMap[game.team2Id]?.name ?? 'Team 2'),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (game.scheduledDateTime != null) ...[
              Text('Scheduled: ${game.scheduledDateTime}'),
              const SizedBox(height: 8),
            ],
            if (game.resourceId != null) ...[
              Text('Location: ${_resourceMap[game.resourceId]?.name ?? 'Unknown'}'),
              const SizedBox(height: 8),
            ],
            Text('Status: ${game.statusDisplayName}'),
            if (game.hasResults) ...[
              const SizedBox(height: 8),
              Text('Result: ${game.resultSummary}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 