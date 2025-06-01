import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/game_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/tournament_resource_model.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/repositories/tournament_resource_repository.dart';
import '../widgets/generate_schedule_dialog.dart';

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
  
  List<GameModel> _allGames = [];
  List<GameModel> _scheduledGames = [];
  List<GameModel> _completedGames = [];
  List<TeamModel> _teams = [];
  List<TournamentResourceModel> _resources = [];
  Map<String, TeamModel> _teamMap = {};
  Map<String, TournamentResourceModel> _resourceMap = {};
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  bool _isScheduleView = false;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      
      setState(() {
        _allGames = games;
        _scheduledGames = games.where((g) => g.status == GameStatus.scheduled).toList();
        _completedGames = games.where((g) => g.status == GameStatus.completed).toList();
        _teams = teams;
        _resources = resources;
        _teamMap = teamMap;
        _resourceMap = resourceMap;
        _stats = stats;
        _isLoading = false;
      });
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
              text: 'All Games (${_allGames.length})',
            ),
            Tab(
              icon: const Icon(Icons.event),
              text: 'Scheduled (${_scheduledGames.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text: 'Completed (${_completedGames.length})',
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
                  // TODO: Implement export functionality
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
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGamesTab(_allGames, 'No games scheduled yet'),
                      _buildGamesTab(_scheduledGames, 'No upcoming games'),
                      _buildGamesTab(_completedGames, 'No completed games yet'),
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
                            ? _getConflictDetails(candidateData.first!, date, time)
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
    return Draggable<GameModel>(
      data: game,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
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
        // Show detailed conflict message
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
                    'Try dropping on a different time slot or court',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
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
    return Container(
      width: double.infinity,
      height: 55, // Slightly increased from 50 to fit content better
      padding: const EdgeInsets.all(2), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4), // Smaller radius
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start, // Changed from center to start
        children: [
          // Game name - make it smaller
          Text(
            game.displayName,
            style: const TextStyle(
              fontSize: 8, // Reduced from 10 to 8
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (game.hasTeams) ...[
            const SizedBox(height: 1), // Reduced spacing
            Text(
              '${_getTeamName(game.team1Id ?? '')} vs ${_getTeamName(game.team2Id ?? '')}',
              style: const TextStyle(
                fontSize: 7, // Reduced from 9 to 7
                color: Colors.black87,
              ),
              maxLines: 2, // Allow 2 lines for team names
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(), // Push time to bottom
          if (game.scheduledTime != null) ...[
            Row(
              children: [
                Icon(Icons.schedule, size: 6, color: Colors.grey[600]), // Smaller icon
                const SizedBox(width: 1),
                Expanded(
                  child: Text(
                    game.scheduledTime!,
                    style: TextStyle(
                      fontSize: 6, // Reduced from 8 to 6
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
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

      // Check if this is the same slot the game is already in
      if (game.scheduledDate != null && game.scheduledTime != null) {
        final isSameDate = _isSameDate(game.scheduledDate!, targetDateTime);
        final isSameTime = game.scheduledTime == targetTime;
        if (isSameDate && isSameTime) {
          return true; // Allow dropping in the same slot (no-op)
        }
      }

      // Check if there are conflicting games at this time slot
      final conflictingGames = _allGames.where((otherGame) {
        if (otherGame.id == game.id) return false; // Don't check against itself
        
        if (otherGame.scheduledDate != null && otherGame.scheduledTime != null) {
          final isSameDate = _isSameDate(otherGame.scheduledDate!, targetDateTime);
          final isSameTime = otherGame.scheduledTime == targetTime;
          
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
      final conflictDetails = _getConflictDetails(game, targetDate, normalizedTime);
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
                  conflictDetails,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            
            // Teams info
            if (game.hasTeams) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Team 1: ${_teamMap[game.team1Id]?.name ?? 'Team 1'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Team 2: ${_teamMap[game.team2Id]?.name ?? 'Team 2'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (game.hasResults) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        game.resultSummary!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
                  Expanded(
                    child: Text(
                      _resourceMap[game.resourceId]?.name ?? 'Court ${game.resourceId?.substring(0, 8)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (game.canEdit) ...[
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    onPressed: () => _showGameOptions(game),
                  ),
                  _buildActionButton(
                    icon: Icons.play_arrow,
                    label: 'Start',
                    onPressed: game.canStart ? () => _startGame(game) : null,
                  ),
                ],
                if (game.status == GameStatus.inProgress) ...[
                  _buildActionButton(
                    icon: Icons.sports_score,
                    label: 'Complete',
                    onPressed: () => _showCompleteGameDialog(game),
                  ),
                ],
                _buildActionButton(
                  icon: Icons.more_vert,
                  label: 'More',
                  onPressed: () => _showGameOptions(game),
                ),
              ],
            ),
          ],
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

  // Enhanced conflict detection with specific details
  String _getConflictDetails(GameModel game, String targetDate, String targetTime) {
    try {
      final dateParts = targetDate.split('/');
      if (dateParts.length != 3) return 'Invalid date format';
      
      final targetDateTime = DateTime(
        int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]),
      );

      final conflictingTeams = <String>[];
      
      for (final otherGame in _allGames) {
        if (otherGame.id == game.id) continue;
        
        if (otherGame.scheduledDate != null && otherGame.scheduledTime != null) {
          final isSameDate = _isSameDate(otherGame.scheduledDate!, targetDateTime);
          final isSameTime = otherGame.scheduledTime == targetTime;
          
          if (isSameDate && isSameTime) {
            if (otherGame.team1Id == game.team1Id || otherGame.team1Id == game.team2Id) {
              final teamName = _getTeamName(otherGame.team1Id ?? '');
              if (!conflictingTeams.contains(teamName)) conflictingTeams.add(teamName);
            }
            if (otherGame.team2Id == game.team1Id || otherGame.team2Id == game.team2Id) {
              final teamName = _getTeamName(otherGame.team2Id ?? '');
              if (!conflictingTeams.contains(teamName)) conflictingTeams.add(teamName);
            }
          }
        }
      }

      if (conflictingTeams.isEmpty) return 'No conflicts found';
      
      return conflictingTeams.length == 1 
          ? '${conflictingTeams.first} is already playing at $targetTime'
          : '${conflictingTeams.join(' and ')} are already playing at $targetTime';
    } catch (e) {
      return 'Error checking conflicts';
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

  void _showHelpDialog() {}
  void _showGameOptions(GameModel game) {}
  void _showCompleteGameDialog(GameModel game) {}
  Future<void> _startGame(GameModel game) async {}
  
  // Example of enhanced conflict messaging
  void _showConflictExample(GameModel game) {
    final conflictDetails = _getConflictDetails(game, '30/8/2025', '06:00');
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
              conflictDetails,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
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
            height: timeSlots.length * 55 + 35, // Dynamic height based on time slots
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 4, // Reduced spacing
                horizontalMargin: 8,
                headingRowHeight: 35, // Reduced header height
                dataRowHeight: 55, // Match our compact cards
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11, // Smaller header text
                ),
                columns: [
                  const DataColumn(
                    label: SizedBox(
                      width: 50, // Reduced time column width
                      child: Text('Time'),
                    ),
                  ),
                  ..._resources.map((resource) => DataColumn(
                    label: SizedBox(
                      width: 160, // Reduced court column width to fit more
                      child: Text(
                        resource.name,
                        style: const TextStyle(fontSize: 11),
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
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            timeSlot,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      ..._resources.map((resource) {
                        final game = dayGames.where((g) => 
                          g.scheduledTime == timeSlot && g.resourceId == resource.id
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
          width: 160, // Reduced width to fit more courts
          height: 55,
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
                          size: 16, // Smaller icon
                        ),
                        const SizedBox(height: 2),
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
                            fontSize: 8, // Smaller text
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
    return Draggable<GameModel>(
      data: game,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 180, // Smaller feedback for grid
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Moving: ${game.displayName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.blue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_getTeamName(game.team1Id ?? '')} vs ${_getTeamName(game.team2Id ?? '')}',
                  style: const TextStyle(fontSize: 8),
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
        print('Grid drag started: ${game.displayName}');
      },
      onDragEnd: (details) {
        HapticFeedback.lightImpact();
        print('Grid drag ended: ${game.displayName}');
      },
      onDragCompleted: () {
        HapticFeedback.mediumImpact();
        print('Grid drag completed: ${game.displayName}');
      },
      onDraggableCanceled: (velocity, offset) {
        HapticFeedback.heavyImpact();
        print('Grid drag canceled: ${game.displayName}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Move canceled for ${game.displayName}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      dragAnchorStrategy: (draggable, context, position) {
        return const Offset(90, 30); // Center of the feedback widget
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

      // Check if this is the same slot the game is already in
      if (game.scheduledDate != null && game.scheduledTime != null && game.resourceId != null) {
        final isSameDate = _isSameDate(game.scheduledDate!, targetDateTime);
        final isSameTime = game.scheduledTime == targetTime;
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
        otherGame.scheduledTime == targetTime &&
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
        otherGame.scheduledTime == targetTime &&
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
    
    print('Grid drop: ${game.displayName} to $targetDate $normalizedTime resource: $resourceId');
    
    if (!_canDropGameToResource(game, targetDate, normalizedTime, resourceId)) {
      final conflictDetails = _getConflictDetails(game, targetDate, normalizedTime);
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
                  conflictDetails,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
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
} 