import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamapp3/core/models/game_model.dart';
import 'package:teamapp3/core/models/team_model.dart';
import 'package:teamapp3/core/models/tournament_resource_model.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_group_model.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_tier_model.dart';
import 'package:teamapp3/features/tournaments/data/services/tiered_tournament_service.dart';
import 'package:teamapp3/features/tournaments/data/services/bracket_generator_service.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_group_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_tier_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/game_repository.dart';

class TieredScheduleManager extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final List<TeamModel> teams;
  final List<TournamentResourceModel> resources;
  final List<GameModel> existingGames;
  final VoidCallback onScheduleUpdated;

  const TieredScheduleManager({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.teams,
    required this.resources,
    required this.existingGames,
    required this.onScheduleUpdated,
  });

  @override
  State<TieredScheduleManager> createState() => _TieredScheduleManagerState();
}

class _TieredScheduleManagerState extends State<TieredScheduleManager>
    with SingleTickerProviderStateMixin {
  late TabController _phaseTabController;
  final TournamentGroupRepository _groupRepository = TournamentGroupRepository();
  final TournamentTierRepository _tierRepository = TournamentTierRepository();
  final GameRepository _gameRepository = GameRepository();
  final BracketGeneratorService _bracketGenerator = BracketGeneratorService();

  // Phase management
  TieredTournamentPhase _currentPhase = TieredTournamentPhase.setup;
  List<TournamentGroupModel> _groups = [];
  List<TournamentTierModel> _tierAssignments = [];
  TieredTournamentStructure? _structure;

  // UI state
  bool _isLoading = false;
  bool _isGeneratingSchedule = false;
  bool _isScheduleView = false;
  bool _isGroupView = false;
  
  // Game data cache to avoid parent rebuilds
  List<GameModel> _cachedGames = [];

  @override
  void initState() {
    super.initState();
    _phaseTabController = TabController(length: 4, vsync: this);
    _cachedGames = List.from(widget.existingGames);
    _initializeTournamentState();
  }

  @override
  void didUpdateWidget(TieredScheduleManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update cached games if they actually changed
    if (widget.existingGames.length != _cachedGames.length ||
        !_gamesListEqual(widget.existingGames, _cachedGames)) {
      _cachedGames = List.from(widget.existingGames);
    }
  }

  bool _gamesListEqual(List<GameModel> list1, List<GameModel> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].status != list2[i].status ||
          list1[i].team1Score != list2[i].team1Score ||
          list1[i].team2Score != list2[i].team2Score) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _phaseTabController.dispose();
    super.dispose();
  }

  Future<void> _initializeTournamentState() async {
    setState(() => _isLoading = true);
    
    try {
      // Calculate tournament structure
      _structure = TieredTournamentService.calculateOptimalStructure(widget.teams.length);
      
      // Load existing groups and tier assignments
      _groups = await _groupRepository.getGroupsByTournament(widget.tournamentId);
      _tierAssignments = await _tierRepository.getTiersByTournament(widget.tournamentId);
      
      // Determine current phase only if not already set
      if (_currentPhase == TieredTournamentPhase.setup) {
        _currentPhase = _determineCurrentPhase();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to initialize tournament: $e');
    }
  }

  TieredTournamentPhase _determineCurrentPhase() {
    if (_groups.isEmpty) {
      return TieredTournamentPhase.setup;
    }
    
    // Check if group stage games exist
    final groupStageGames = _cachedGames.where((game) =>
      game.notes?.contains('Group Stage') == true ||
      game.roundName?.contains('Group') == true
    ).toList();
    
    if (groupStageGames.isEmpty) {
      return TieredTournamentPhase.groupStage;
    }
    
    // Check if group stage is complete
    final completedGroupGames = groupStageGames.where((g) => g.status == GameStatus.completed).length;
    final isGroupStageComplete = completedGroupGames == groupStageGames.length && groupStageGames.isNotEmpty;
    
    if (!isGroupStageComplete) {
      return TieredTournamentPhase.groupStage;
    }
    
    // Check if tier assignments exist
    if (_tierAssignments.isEmpty) {
      return TieredTournamentPhase.tierClassification;
    }
    
    // Check if tier playoff games exist
    final tierPlayoffGames = _cachedGames.where((game) =>
      game.notes?.contains('Tier') == true ||
      game.roundName?.contains('Elimination') == true
    ).toList();
    
    if (tierPlayoffGames.isEmpty) {
      return TieredTournamentPhase.tieredPlayoffs;
    }
    
    return TieredTournamentPhase.tieredPlayoffs;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header Card with Phase Info
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.8),
                Theme.of(context).primaryColor.withOpacity(0.6),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getPhaseIcon(_currentPhase),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Phase: ${_getPhaseDisplayName(_currentPhase)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getPhaseDescription(_currentPhase),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Schedule Actions Menu in Header
                      if (_currentPhase == TieredTournamentPhase.groupStage)
                        _buildHeaderScheduleActions(),
                    ],
                  ),
                  if (_structure != null) ...[
                    const SizedBox(height: 16),
                    _buildTournamentStructureInfo(),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Phase Tabs
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: _buildPhaseTabBar(),
        ),
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _phaseTabController,
            children: [
              _buildSetupPhase(),
              _buildGroupStagePhase(),
              _buildTierClassificationPhase(),
              _buildTieredPlayoffsPhase(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentStructureInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Structure',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStructureInfo(
                  'Teams',
                  '${_structure!.usableTeams}/${_structure!.totalTeams}',
                  Icons.groups,
                ),
              ),
              Expanded(
                child: _buildStructureInfo(
                  'Groups',
                  '${_structure!.numGroups} groups of ${_structure!.groupSize}',
                  Icons.view_module,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStructureInfo(
                  'Pro Tier',
                  '${_structure!.proTierTeams} teams',
                  Icons.emoji_events,
                ),
              ),
              Expanded(
                child: _buildStructureInfo(
                  'Intermediate',
                  '${_structure!.intermediateTierTeams} teams',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStructureInfo(
                  'Novice',
                  '${_structure!.noviceTierTeams} teams',
                  Icons.school,
                ),
              ),
            ],
          ),
          if (_structure!.eliminatedTeams > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_structure!.eliminatedTeams} teams will be eliminated due to structure constraints',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStructureInfo(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderScheduleActions() {
    final groupStageGames = _cachedGames.where((game) =>
      game.notes?.contains('Group Stage') == true ||
      game.roundName?.contains('Group') == true
    ).toList();
    
    final hasInProgressOrCompleted = groupStageGames.any((g) => 
      g.status == GameStatus.inProgress || g.status == GameStatus.completed);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: PopupMenuButton<String>(
        enabled: !_isGeneratingSchedule,
        offset: const Offset(0, 40),
        icon: Icon(
          _isGeneratingSchedule ? Icons.hourglass_empty : Icons.more_vert,
          color: Colors.white,
        ),
        tooltip: 'Schedule Actions',
        itemBuilder: (context) => [
          if (groupStageGames.isEmpty) ...[
            PopupMenuItem<String>(
              value: 'generate',
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generate Schedule',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Create optimized court schedule',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (!hasInProgressOrCompleted) ...[
              PopupMenuItem<String>(
                value: 'regenerate',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Regenerate Schedule',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Apply optimized court assignments',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            PopupMenuItem<String>(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.sync, color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Refresh View',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Reload schedule from database',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, color: Colors.red[600], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete All Games',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Clear all games and results',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.purple[600], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Schedule',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Download as CSV or PDF',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        onSelected: (value) {
          if (value == 'generate') {
            _generateGroupStageSchedule();
          } else {
            _handleScheduleAction(value, hasInProgressOrCompleted);
          }
        },
      ),
    );
  }

  Widget _buildPhaseTabBar() {
    return TabBar(
      controller: _phaseTabController,
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).primaryColor,
      tabs: [
        Tab(
          icon: Icon(_getPhaseIcon(TieredTournamentPhase.setup)),
          text: 'Setup',
        ),
        Tab(
          icon: Icon(_getPhaseIcon(TieredTournamentPhase.groupStage)),
          text: 'Group Stage',
        ),
        Tab(
          icon: Icon(_getPhaseIcon(TieredTournamentPhase.tierClassification)),
          text: 'Classification',
        ),
        Tab(
          icon: Icon(_getPhaseIcon(TieredTournamentPhase.tieredPlayoffs)),
          text: 'Playoffs',
        ),
      ],
    );
  }

  Widget _buildSetupPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tournament Setup',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate groups and initial structure for the tiered tournament.',
          ),
          const SizedBox(height: 16),
          if (_groups.isEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generate Groups',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Create groups using snake-draft seeding for balanced competition.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isGeneratingSchedule ? null : _generateGroups,
                      icon: _isGeneratingSchedule
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGeneratingSchedule ? 'Generating...' : 'Generate Groups'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildGroupsDisplay(),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupStagePhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Group Stage - Round Robin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Teams compete within their groups in round-robin format.',
          ),
          const SizedBox(height: 16),
          if (_groups.isNotEmpty) ...[
            _buildGroupStageScheduling(),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.warning, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Groups Not Generated',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Please complete the Setup phase first.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _phaseTabController.animateTo(0),
                      child: const Text('Go to Setup'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTierClassificationPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tier Classification',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sort teams into Pro, Intermediate, and Novice tiers based on group stage performance.',
          ),
          const SizedBox(height: 16),
          _buildTierClassificationContent(),
        ],
      ),
    );
  }

  Widget _buildTieredPlayoffsPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiered Playoffs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Separate elimination brackets for each tier.',
          ),
          const SizedBox(height: 16),
          _buildTieredPlayoffsContent(),
        ],
      ),
    );
  }

  Widget _buildGroupsDisplay() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Generated Groups',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _regenerateGroups,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Regenerate Groups',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_groups.length, (index) {
              final group = _groups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildGroupCard(group),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(TournamentGroupModel group) {
    final groupTeams = widget.teams.where((team) => group.teamIds.contains(team.id)).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.groupName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: groupTeams.map((team) => Chip(
              label: Text(team.name),
              backgroundColor: Colors.blue.shade100,
              labelStyle: TextStyle(color: Colors.blue.shade800),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStageScheduling() {
    final groupStageGames = _cachedGames.where((game) =>
      game.notes?.contains('Group Stage') == true ||
      game.roundName?.contains('Group') == true
    ).toList();

    return Column(
      children: [
        // Header Card with Stats and Controls
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Group Stage Schedule',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (groupStageGames.isNotEmpty)
                      _buildViewToggle(),
                  ],
                ),
                const SizedBox(height: 16),
                if (groupStageGames.isEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      const Text('No group stage games scheduled yet.'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isGeneratingSchedule ? null : _generateGroupStageSchedule,
                    icon: _isGeneratingSchedule
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.calendar_today),
                    label: Text(_isGeneratingSchedule ? 'Generating...' : 'Generate Group Stage Schedule'),
                  ),
                ] else ...[
                  _buildGroupStageStats(groupStageGames),
                ],
              ],
            ),
          ),
        ),
        
        // Schedule Content
        if (groupStageGames.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 400, // Fixed height instead of Expanded
            child: _isScheduleView 
                ? _buildGroupStageScheduleView(groupStageGames)
                : _isGroupView
                    ? _buildGroupStageGroupView(groupStageGames)
                    : _buildGroupStageListView(groupStageGames),
          ),
        ],
      ],
    );
  }

  Widget _buildTierClassificationContent() {
    // Check if group stage is complete
    final groupStageGames = _cachedGames.where((game) =>
      game.notes?.contains('Group Stage') == true ||
      game.roundName?.contains('Group') == true
    ).toList();
    
    final isGroupStageComplete = groupStageGames.isNotEmpty &&
        groupStageGames.every((g) => g.status == GameStatus.completed);

    if (!isGroupStageComplete) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.hourglass_empty, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Waiting for Group Stage Completion',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Complete all group stage games before tier classification.'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calculate Tier Assignments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_tierAssignments.isEmpty) ...[
              const Text('Group stage complete! Ready to calculate tier assignments.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isGeneratingSchedule ? null : _calculateTierAssignments,
                icon: _isGeneratingSchedule
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics),
                label: Text(_isGeneratingSchedule ? 'Calculating...' : 'Calculate Tier Assignments'),
              ),
            ] else ...[
              _buildTierAssignmentsDisplay(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTierAssignmentsDisplay() {
    final proTeams = _tierAssignments.where((t) => t.tier == TournamentTier.pro).toList();
    final intermediateTeams = _tierAssignments.where((t) => t.tier == TournamentTier.intermediate).toList();
    final noviceTeams = _tierAssignments.where((t) => t.tier == TournamentTier.novice).toList();

    return Column(
      children: [
              _buildTierCard('Pro Tier', proTeams, const Color(0xFFFFD700)),
      const SizedBox(height: 12),
      _buildTierCard('Intermediate Tier', intermediateTeams, const Color(0xFFC0C0C0)),
      const SizedBox(height: 12),
      _buildTierCard('Novice Tier', noviceTeams, const Color(0xFFCD7F32)),
      ],
    );
  }

  Widget _buildTierCard(String tierName, List<TournamentTierModel> tierTeams, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                tierName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8),
                ),
              ),
              const Spacer(),
              Text('${tierTeams.length} teams'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tierTeams.map((tierTeam) {
              final team = widget.teams.firstWhere((t) => t.id == tierTeam.teamId);
              return Container(
                margin: const EdgeInsets.only(right: 4, bottom: 4),
                child: Chip(
                  avatar: CircleAvatar(
                    backgroundColor: color,
                    radius: 12,
                    child: Text(
                      '${tierTeam.tierSeed}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: Text(team.name),
                  backgroundColor: color.withOpacity(0.1),
                  labelStyle: TextStyle(color: color.withOpacity(0.9)),
                  side: BorderSide(color: color.withOpacity(0.3)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTieredPlayoffsContent() {
    if (_tierAssignments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.hourglass_empty, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Waiting for Tier Classification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Complete tier classification before generating playoffs.'),
            ],
          ),
        ),
      );
    }

    final tierPlayoffGames = _cachedGames.where((game) =>
      game.notes?.contains('Tier') == true ||
      game.notes?.contains('Elimination') == true ||
      game.roundName?.contains('Elimination') == true ||
      game.roundName?.contains('Final') == true ||
      game.roundName?.contains('Semi') == true ||
      game.roundName?.contains('Quarter') == true
    ).toList();

    print('🎯 Found ${tierPlayoffGames.length} playoff games in cache');
    // Debug: Log details about each playoff game
    for (final game in tierPlayoffGames) {
      print('🏆 Playoff Game: ${game.roundName} - ${game.notes} - Teams: ${game.team1Id} vs ${game.team2Id}');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiered Playoff Brackets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (tierPlayoffGames.isNotEmpty) ...[
                  Row(
                    children: [
                      IconButton(
                        onPressed: _clearAllPlayoffGames,
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        tooltip: 'Clear All Playoff Games',
                      ),
                      _buildViewToggle(),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (tierPlayoffGames.isEmpty) ...[
              const Text('Generate elimination brackets for each tier.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isGeneratingSchedule ? null : _generateTieredPlayoffs,
                icon: _isGeneratingSchedule
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_tree),
                label: Text(_isGeneratingSchedule ? 'Generating...' : 'Generate Tiered Playoffs'),
              ),
            ] else ...[
              _buildTierPlayoffStats(tierPlayoffGames),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: _isScheduleView 
                    ? _buildTierPlayoffScheduleView(tierPlayoffGames)
                    : _buildTierPlayoffListView(tierPlayoffGames),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods for phase management
  IconData _getPhaseIcon(TieredTournamentPhase phase) {
    switch (phase) {
      case TieredTournamentPhase.setup:
        return Icons.settings;
      case TieredTournamentPhase.groupStage:
        return Icons.groups;
      case TieredTournamentPhase.tierClassification:
        return Icons.analytics;
      case TieredTournamentPhase.tieredPlayoffs:
        return Icons.emoji_events;
    }
  }

  Color _getPhaseColor(TieredTournamentPhase phase) {
    switch (phase) {
      case TieredTournamentPhase.setup:
        return Colors.grey;
      case TieredTournamentPhase.groupStage:
        return Colors.blue;
      case TieredTournamentPhase.tierClassification:
        return Colors.orange;
      case TieredTournamentPhase.tieredPlayoffs:
        return Colors.purple;
    }
  }

  String _getPhaseDisplayName(TieredTournamentPhase phase) {
    switch (phase) {
      case TieredTournamentPhase.setup:
        return 'Setup';
      case TieredTournamentPhase.groupStage:
        return 'Group Stage';
      case TieredTournamentPhase.tierClassification:
        return 'Tier Classification';
      case TieredTournamentPhase.tieredPlayoffs:
        return 'Tiered Playoffs';
    }
  }

  String _getPhaseDescription(TieredTournamentPhase phase) {
    switch (phase) {
      case TieredTournamentPhase.setup:
        return 'Generate groups and prepare tournament structure';
      case TieredTournamentPhase.groupStage:
        return 'Round-robin competition within groups';
      case TieredTournamentPhase.tierClassification:
        return 'Sort teams into performance-based tiers';
      case TieredTournamentPhase.tieredPlayoffs:
        return 'Elimination brackets for each tier';
    }
  }

  // Action methods
  Future<void> _generateGroups() async {
    setState(() => _isGeneratingSchedule = true);
    
    try {
      final groups = TieredTournamentService.generateGroups(
        tournamentId: widget.tournamentId,
        teams: widget.teams,
        structure: _structure!,
      );
      
      // Save groups to database
      for (final group in groups) {
        await _groupRepository.createGroup(group);
      }
      
      setState(() {
        _groups = groups;
        _currentPhase = TieredTournamentPhase.groupStage;
      });
      
      _showSuccessSnackBar('Groups generated successfully!');
      widget.onScheduleUpdated();
    } catch (e) {
      _showErrorSnackBar('Failed to generate groups: $e');
    } finally {
      setState(() => _isGeneratingSchedule = false);
    }
  }

  Future<void> _regenerateGroups() async {
    final confirmed = await _showConfirmationDialog(
      'Regenerate Groups',
      'This will delete existing groups and regenerate them. Continue?',
    );
    
    if (!confirmed) return;
    
    setState(() => _isGeneratingSchedule = true);
    
    try {
      // Delete existing groups
      for (final group in _groups) {
        await _groupRepository.deleteGroup(group.id);
      }
      
      await _generateGroups();
    } catch (e) {
      _showErrorSnackBar('Failed to regenerate groups: $e');
    } finally {
      setState(() => _isGeneratingSchedule = false);
    }
  }

  Future<void> _generateGroupStageSchedule() async {
    if (_groups.isEmpty) {
      _showErrorSnackBar('Please generate groups first');
      return;
    }
    
    setState(() => _isGeneratingSchedule = true);
    
    try {
      // Show schedule generation dialog
      final scheduleParams = await _showScheduleGenerationDialog();
      if (scheduleParams == null) {
        setState(() => _isGeneratingSchedule = false);
        return;
      }
      
      final resourceIds = widget.resources.map((r) => r.id).toList();
      
      final games = TieredTournamentService.generateGroupStageGames(
        tournamentId: widget.tournamentId,
        groups: _groups,
        resourceIds: resourceIds,
        tournamentStart: scheduleParams['startDate'] as DateTime,
        gameDurationMinutes: scheduleParams['gameDuration'] as int,
        timeBetweenGamesMinutes: scheduleParams['timeBetweenGames'] as int,
      );
      
      // Create games in database
      for (final game in games) {
        await _gameRepository.createGame(
          tournamentId: game.tournamentId,
          categoryId: game.categoryId,
          round: game.round,
          roundName: game.roundName ?? 'Group Stage',
          gameNumber: game.gameNumber,
          team1Id: game.team1Id,
          team2Id: game.team2Id,
          resourceId: game.resourceId,
          scheduledDate: game.scheduledDate,
          scheduledTime: game.scheduledTime,
          estimatedDuration: game.estimatedDuration,
          notes: game.notes,
          isPublished: true,
        );
      }
      
      _showSuccessSnackBar('Group stage schedule generated!');
      widget.onScheduleUpdated();
    } catch (e) {
      _showErrorSnackBar('Failed to generate schedule: $e');
    } finally {
      setState(() => _isGeneratingSchedule = false);
    }
  }

  Future<void> _regenerateSchedule() async {
    final confirmed = await _showConfirmationDialog(
      'Regenerate Schedule',
      'This will delete all existing scheduled games and recreate them with optimized court assignments. Continue?',
    );
    
    if (!confirmed) return;
    
    setState(() => _isGeneratingSchedule = true);
    
    try {
      // Delete existing group stage games (only scheduled ones)
      final groupStageGames = _cachedGames.where((game) =>
        (game.notes?.contains('Group Stage') == true ||
         game.roundName?.contains('Group') == true) &&
        game.status == GameStatus.scheduled
      ).toList();
      
      for (final game in groupStageGames) {
        await _gameRepository.deleteGame(game.id);
      }
      
      // Regenerate with new optimized scheduling
      await _generateGroupStageSchedule();
      
      _showSuccessSnackBar('Schedule regenerated with optimized court assignments!');
    } catch (e) {
      _showErrorSnackBar('Failed to regenerate schedule: $e');
    } finally {
      setState(() => _isGeneratingSchedule = false);
    }
  }

  Future<void> _clearAllGames() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Games',
      'This will permanently delete ALL group stage games including results and progress. This action cannot be undone. Continue?',
    );
    
    if (!confirmed) return;
    
    // Show additional warning for games with results
    final gamesWithResults = _cachedGames.where((game) =>
      (game.notes?.contains('Group Stage') == true ||
       game.roundName?.contains('Group') == true) &&
      (game.status == GameStatus.completed || game.status == GameStatus.inProgress)
    ).toList();
    
    if (gamesWithResults.isNotEmpty) {
      final doubleConfirmed = await _showConfirmationDialog(
        'Final Warning',
        '${gamesWithResults.length} games have results or are in progress. All data will be lost permanently. Are you absolutely sure?',
      );
      
      if (!doubleConfirmed) return;
    }
    
    setState(() => _isGeneratingSchedule = true);
    
    try {
      // Delete all group stage games
      final groupStageGames = _cachedGames.where((game) =>
        game.notes?.contains('Group Stage') == true ||
        game.roundName?.contains('Group') == true
      ).toList();
      
      for (final game in groupStageGames) {
        await _gameRepository.deleteGame(game.id);
      }
      
      _showSuccessSnackBar('All group stage games cleared successfully!');
      widget.onScheduleUpdated();
    } catch (e) {
      _showErrorSnackBar('Failed to clear games: $e');
    } finally {
      setState(() => _isGeneratingSchedule = false);
    }
  }

  Future<void> _clearAllPlayoffGames() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Playoff Games',
      'This will permanently delete ALL tiered playoff games including results and progress. This action cannot be undone. Continue?',
    );
    
    if (!confirmed) return;
    
    // Show additional warning for games with results
    final playoffGamesWithResults = _cachedGames.where((game) =>
      (game.notes?.contains('Tier') == true ||
       game.notes?.contains('Elimination') == true ||
       game.roundName?.contains('Elimination') == true ||
       game.roundName?.contains('Final') == true ||
       game.roundName?.contains('Semi') == true ||
       game.roundName?.contains('Quarter') == true) &&
      (game.status == GameStatus.completed || game.status == GameStatus.inProgress)
    ).toList();
    
    if (playoffGamesWithResults.isNotEmpty) {
      final doubleConfirmed = await _showConfirmationDialog(
        'Final Warning',
        '${playoffGamesWithResults.length} playoff games have results or are in progress. All data will be lost permanently. Are you absolutely sure?',
      );
      
      if (!doubleConfirmed) return;
    }
    
    setState(() => _isGeneratingSchedule = true);
    
    try {
      // Delete all playoff games
      final playoffGames = _cachedGames.where((game) =>
        game.notes?.contains('Tier') == true ||
        game.notes?.contains('Elimination') == true ||
        game.roundName?.contains('Elimination') == true ||
        game.roundName?.contains('Final') == true ||
        game.roundName?.contains('Semi') == true ||
        game.roundName?.contains('Quarter') == true
      ).toList();
      
      print('🗑️ Deleting ${playoffGames.length} playoff games...');
      for (final game in playoffGames) {
        print('🗑️ Deleting game: ${game.roundName} - ${game.notes}');
        await _gameRepository.deleteGame(game.id);
      }
      
      // Refresh the local game state
      await _refreshLocalGameState();
      
      _showSuccessSnackBar('All playoff games cleared successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to clear playoff games: $e');
    } finally {
      setState(() => _isGeneratingSchedule = false);
    }
  }

  void _handleScheduleAction(String action, bool hasInProgressOrCompleted) {
    switch (action) {
      case 'regenerate':
        if (!hasInProgressOrCompleted) {
          _regenerateSchedule();
        }
        break;
      case 'refresh':
        _refreshSchedule();
        break;
      case 'clear':
        _clearAllGames();
        break;
      case 'export':
        _exportSchedule();
        break;
    }
  }

  void _refreshSchedule() {
    _showSuccessSnackBar('Schedule refreshed!');
    widget.onScheduleUpdated();
  }

  void _exportSchedule() {
    // Placeholder for export functionality
    _showSuccessSnackBar('Export functionality coming soon!');
  }

  Widget _buildGameActionButtons(GameModel game) {
    switch (game.status) {
      case GameStatus.scheduled:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _startGame(game),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Start Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateGameScore(game),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Enter Score'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        );
      
      case GameStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateGameScore(game),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update Score'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _completeGame(game),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      
      case GameStatus.completed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateGameScore(game),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Score'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _resetGameToScheduled(game),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _refreshLocalGameState() async {
    try {
      print('🔄 Fetching updated games from database...');
      // Refresh games locally without calling parent
      final updatedGames = await _gameRepository.getTournamentGames(widget.tournamentId);
      print('📥 Fetched ${updatedGames.length} games from database');
      
      setState(() {
        _cachedGames = updatedGames;
      });
      print('✅ Local game state updated successfully');
    } catch (e) {
      print('❌ Error refreshing game state: $e');
      // Fallback to parent refresh if local refresh fails
      widget.onScheduleUpdated();
    }
  }

  Future<void> _startGame(GameModel game) async {
    try {
      await _gameRepository.startGame(game.id);
      _showSuccessSnackBar('Game started!');
      // Refresh local state instead of calling parent callback immediately
      await _refreshLocalGameState();
    } catch (e) {
      _showErrorSnackBar('Failed to start game: $e');
    }
  }

  Future<void> _updateGameScore(GameModel game) async {
    final team1 = widget.teams.firstWhere((t) => t.id == game.team1Id);
    final team2 = widget.teams.firstWhere((t) => t.id == game.team2Id);
    
    final result = await _showScoreDialog(
      team1: team1,
      team2: team2,
      currentScore1: game.team1Score,
      currentScore2: game.team2Score,
    );
    
    if (result != null) {
      try {
        final team1Score = result['team1Score'] as int;
        final team2Score = result['team2Score'] as int;
        
        // Determine winner
        String? winnerId;
        if (team1Score != team2Score) {
          winnerId = team1Score > team2Score ? game.team1Id : game.team2Id;
        }
        
        // Update scores in database directly
        await _updateScoreInDatabase(
          gameId: game.id,
          team1Score: team1Score,
          team2Score: team2Score,
          winnerId: winnerId,
        );
        
        // Auto-start game if it was scheduled
        if (game.status == GameStatus.scheduled) {
          await _gameRepository.updateGame(gameId: game.id, status: GameStatus.inProgress);
        }
        
        _showSuccessSnackBar('Score updated!');
        await _refreshLocalGameState();
      } catch (e) {
        _showErrorSnackBar('Failed to update score: $e');
      }
    }
  }

  Future<void> _completeGame(GameModel game) async {
    // Check if game has scores before completing
    if (game.team1Score == null || game.team2Score == null) {
      final shouldAddScore = await _showConfirmationDialog(
        'Missing Score',
        'This game has no score recorded. Do you want to add a score before completing?',
      );
      
      if (shouldAddScore) {
        await _updateGameScore(game);
        return;
      }
    }
    
    try {
      // Use the completeGame method with current scores
      final team1Score = game.team1Score ?? 0;
      final team2Score = game.team2Score ?? 0;
      String? winnerId;
      if (team1Score != team2Score) {
        winnerId = team1Score > team2Score ? game.team1Id : game.team2Id;
      }
      
      await _gameRepository.completeGame(
        gameId: game.id,
        team1Score: team1Score,
        team2Score: team2Score,
        winnerId: winnerId,
      );
      
      _showSuccessSnackBar('Game completed!');
      await _refreshLocalGameState();
    } catch (e) {
      _showErrorSnackBar('Failed to complete game: $e');
    }
  }

  Future<void> _resetGameToScheduled(GameModel game) async {
    final confirmed = await _showConfirmationDialog(
      'Reset Game',
      'This will reset the game to scheduled status and clear the score. Continue?',
    );
    
    if (!confirmed) return;
    
    try {
      await _gameRepository.updateGame(gameId: game.id, status: GameStatus.scheduled);
      await _updateScoreInDatabase(
        gameId: game.id,
        team1Score: 0,
        team2Score: 0,
        winnerId: null,
        clearScore: true,
      );
      _showSuccessSnackBar('Game reset to scheduled!');
      await _refreshLocalGameState();
    } catch (e) {
      _showErrorSnackBar('Failed to reset game: $e');
    }
  }

  Future<void> _updateScoreInDatabase({
    required String gameId,
    required int team1Score,
    required int team2Score,
    String? winnerId,
    bool clearScore = false,
  }) async {
    final supabase = Supabase.instance.client;
    
    final updateData = <String, dynamic>{
      'team1_score': clearScore ? null : team1Score,
      'team2_score': clearScore ? null : team2Score,
      'winner_id': winnerId,
    };
    
    await supabase
        .from('games')
        .update(updateData)
        .eq('id', gameId);
  }

  Future<Map<String, int>?> _showScoreDialog({
    required TeamModel team1,
    required TeamModel team2,
    int? currentScore1,
    int? currentScore2,
  }) async {
    final score1Controller = TextEditingController(text: currentScore1?.toString() ?? '');
    final score2Controller = TextEditingController(text: currentScore2?.toString() ?? '');
    
    return await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        team1.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: score1Controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'VS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        team2.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: score2Controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final score1 = int.tryParse(score1Controller.text) ?? 0;
              final score2 = int.tryParse(score2Controller.text) ?? 0;
              Navigator.of(context).pop({
                'team1Score': score1,
                'team2Score': score2,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _calculateTierAssignments() async {
    setState(() => _isGeneratingSchedule = true);
    
    try {
      final completedGames = _cachedGames.where((g) => g.status == GameStatus.completed).toList();
      
      final tierAssignments = TieredTournamentService.calculateTierAssignments(
        tournamentId: widget.tournamentId,
        groups: _groups,
        completedGames: completedGames,
        structure: _structure!,
      );
      
      // Save tier assignments to database
      for (final assignment in tierAssignments) {
        await _tierRepository.createTierAssignment(assignment);
      }
      
      setState(() {
        _tierAssignments = tierAssignments;
        _currentPhase = TieredTournamentPhase.tieredPlayoffs;
      });
      
      _showSuccessSnackBar('Tier assignments calculated!');
      widget.onScheduleUpdated();
    } catch (e) {
      _showErrorSnackBar('Failed to calculate tier assignments: $e');
    } finally {
      setState(() => _isGeneratingSchedule = false);
    }
  }

  Future<void> _generateTieredPlayoffs() async {
    setState(() => _isGeneratingSchedule = true);
    
    try {
      final scheduleParams = await _showScheduleGenerationDialog();
      if (scheduleParams == null) {
        setState(() => _isGeneratingSchedule = false);
        return;
      }
      
      final resourceIds = widget.resources.map((r) => r.id).toList();
      final teamsMap = {for (final team in widget.teams) team.id: team};
      
      final brackets = await _bracketGenerator.generateTieredBrackets(
        tournamentId: widget.tournamentId,
        tierAssignments: _tierAssignments,
        teamsMap: teamsMap,
        resourceIds: resourceIds,
        startDate: scheduleParams['startDate'] as DateTime,
        gameDurationMinutes: scheduleParams['gameDuration'] as int,
        timeBetweenGamesMinutes: scheduleParams['timeBetweenGames'] as int,
      );
      
      print('🔄 Brackets generated, refreshing game state...');
      print('📊 Games before refresh: ${_cachedGames.length}');
      
      // Refresh local game state to show newly generated playoff games
      await _refreshLocalGameState();
      
      print('📊 Games after refresh: ${_cachedGames.length}');
      print('🏁 Current phase before update: $_currentPhase');
      
      // Update phase to playoffs and switch to playoffs tab
      setState(() {
        _currentPhase = TieredTournamentPhase.tieredPlayoffs;
        // Switch to the playoffs tab (index 3)
        _phaseTabController.animateTo(3);
      });
      
      print('🏁 Phase updated to: $_currentPhase');
      
      _showSuccessSnackBar('Tiered playoff brackets generated!');
      widget.onScheduleUpdated();
    } catch (e) {
      _showErrorSnackBar('Failed to generate tiered playoffs: $e');
    } finally {
      setState(() => _isGeneratingSchedule = false);
    }
  }

  Future<Map<String, dynamic>?> _showScheduleGenerationDialog() async {
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    final gameDurationController = TextEditingController(text: '60');
    final timeBetweenGamesController = TextEditingController(text: '15');
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Parameters'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Date
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                subtitle: Text('${startDate.day}/${startDate.month}/${startDate.year}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => startDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Game Duration Input
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Game Duration',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: gameDurationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('minutes'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Break Between Games Input
              Row(
                children: [
                  const Icon(Icons.pause, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Break Between Games',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: timeBetweenGamesController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('minutes'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final gameDuration = int.tryParse(gameDurationController.text) ?? 60;
                final timeBetweenGames = int.tryParse(timeBetweenGamesController.text) ?? 15;
                
                // Validate input ranges
                if (gameDuration < 10 || gameDuration > 300) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Game duration must be between 10 and 300 minutes'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (timeBetweenGames < 0 || timeBetweenGames > 120) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Break time must be between 0 and 120 minutes'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop({
                  'startDate': startDate,
                  'gameDuration': gameDuration,
                  'timeBetweenGames': timeBetweenGames,
                });
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showGroupStageGamesDialog(List<GameModel> games) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Stage Schedule'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: games.isEmpty
              ? const Center(child: Text('No games scheduled'))
              : ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final team1 = widget.teams.firstWhere((t) => t.id == game.team1Id, orElse: () => TeamModel(
                      id: '', name: 'Unknown', tournamentId: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
                    final team2 = widget.teams.firstWhere((t) => t.id == game.team2Id, orElse: () => TeamModel(
                      id: '', name: 'Unknown', tournamentId: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
                    final resource = widget.resources.firstWhere((r) => r.id == game.resourceId, orElse: () => TournamentResourceModel(
                      id: '', tournamentId: '', name: 'TBD', type: ''));

                    return Card(
                      child: ListTile(
                        title: Text('${team1.name} vs ${team2.name}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${game.scheduledDate?.day}/${game.scheduledDate?.month} at ${game.scheduledTime ?? 'TBD'}'),
                            Text('${resource.name} - ${game.roundName ?? 'Group Stage'}'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(game.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            game.status.name.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  },
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

  Widget _buildGamesSummary(List<GameModel> games) {
    final gamesByGroup = <String, List<GameModel>>{};
    for (final game in games) {
      final groupName = game.notes?.split(' - ').first ?? 'Unknown Group';
      gamesByGroup.putIfAbsent(groupName, () => []).add(game);
    }

    return Column(
      children: gamesByGroup.entries.map((entry) {
        final groupName = entry.key;
        final groupGames = entry.value;
        final completedGames = groupGames.where((g) => g.status == GameStatus.completed).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  groupName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '$completedGames/${groupGames.length} completed',
                style: TextStyle(
                  color: completedGames == groupGames.length ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildViewToggle() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'groups',
          label: Text('Groups'),
          icon: Icon(Icons.group_work, size: 16),
        ),
        ButtonSegment(
          value: 'list',
          label: Text('List'),
          icon: Icon(Icons.list, size: 16),
        ),
        ButtonSegment(
          value: 'schedule',
          label: Text('Schedule'),
          icon: Icon(Icons.calendar_view_day, size: 16),
        ),
      ],
      selected: {_isScheduleView ? 'schedule' : (_isGroupView ? 'groups' : 'list')},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          if (newSelection.first == 'schedule') {
            _isScheduleView = true;
            _isGroupView = false;
          } else if (newSelection.first == 'groups') {
            _isScheduleView = false;
            _isGroupView = true;
          } else {
            _isScheduleView = false;
            _isGroupView = false;
          }
        });
      },
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildGroupStageStats(List<GameModel> games) {
    final completed = games.where((g) => g.status == GameStatus.completed).length;
    final inProgress = games.where((g) => g.status == GameStatus.inProgress).length;
    final scheduled = games.where((g) => g.status == GameStatus.scheduled).length;

    return Row(
      children: [
        _buildStatBadge('Total', games.length, Colors.blue),
        const SizedBox(width: 16),
        _buildStatBadge('Scheduled', scheduled, Colors.orange),
        const SizedBox(width: 16),
        _buildStatBadge('In Progress', inProgress, Colors.green),
        const SizedBox(width: 16),
        _buildStatBadge('Completed', completed, Colors.purple),
      ],
    );
  }

  Widget _buildScheduleManagementControls(List<GameModel> games) {
    final hasInProgressOrCompleted = games.any((g) => 
      g.status == GameStatus.inProgress || g.status == GameStatus.completed);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Schedule Management',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (hasInProgressOrCompleted) ...[
            // Warning when games have started
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[600], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some games have started or completed. Clearing will delete all progress.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton<String>(
                    enabled: !_isGeneratingSchedule,
                    offset: const Offset(0, 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isGeneratingSchedule) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            const Text('Processing...'),
                          ] else ...[
                            const Icon(Icons.more_horiz, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Schedule Actions',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: _isGeneratingSchedule ? Colors.grey : Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      if (!hasInProgressOrCompleted) ...[
                        PopupMenuItem<String>(
                          value: 'regenerate',
                          child: Row(
                            children: [
                              Icon(Icons.refresh, color: Colors.blue[600], size: 20),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Regenerate Schedule',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Apply optimized court assignments',
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                      ],
                      PopupMenuItem<String>(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.sync, color: Colors.green[600], size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Refresh View',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Reload schedule from database',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever, color: Colors.red[600], size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delete All Games',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Clear all games and results',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, color: Colors.purple[600], size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Export Schedule',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Download as CSV or PDF',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleScheduleAction(value, hasInProgressOrCompleted),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          Text(
            hasInProgressOrCompleted 
                ? 'Tip: Clear all games first to regenerate with new optimized court assignments'
                : 'Regenerate to apply the new optimized court scheduling',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupStageListView(List<GameModel> games) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildGamesSummary(games),
          const SizedBox(height: 16),
          ...games.map((game) => _buildGroupStageGameCard(game)),
        ],
      ),
    );
  }

  Widget _buildGroupStageGroupView(List<GameModel> games) {
    // Group games by their tournament group
    final gamesByGroup = <String, List<GameModel>>{};
    final groupColors = <String, Color>{};
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    for (final game in games) {
      final groupName = game.notes?.split(' - ').last ?? 'Unknown Group';
      gamesByGroup.putIfAbsent(groupName, () => []).add(game);
      
      // Assign a color to each group if not already assigned
      if (!groupColors.containsKey(groupName)) {
        final colorIndex = groupColors.length % colors.length;
        groupColors[groupName] = colors[colorIndex];
      }
    }

    // Sort groups alphabetically
    final sortedGroups = gamesByGroup.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: sortedGroups.map((groupName) {
          final groupGames = gamesByGroup[groupName]!;
          final groupColor = groupColors[groupName]!;
          final completedGames = groupGames.where((g) => g.status == GameStatus.completed).length;
          final inProgressGames = groupGames.where((g) => g.status == GameStatus.inProgress).length;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: groupColor.withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                // Group Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: groupColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: groupColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.group_work,
                          color: groupColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              groupName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: groupColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${groupGames.length} games • $completedGames completed',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Progress indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: completedGames == groupGames.length 
                              ? Colors.green.withOpacity(0.2)
                              : inProgressGames > 0
                                  ? Colors.orange.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          completedGames == groupGames.length 
                              ? 'Complete'
                              : inProgressGames > 0
                                  ? 'In Progress'
                                  : 'Scheduled',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: completedGames == groupGames.length 
                                ? Colors.green[700]
                                : inProgressGames > 0
                                    ? Colors.orange[700]
                                    : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Group Games
                ...groupGames.map((game) => Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildGroupGameCard(game, groupColor),
                )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupGameCard(GameModel game, Color groupColor) {
    final team1 = widget.teams.firstWhere((t) => t.id == game.team1Id, 
        orElse: () => TeamModel(id: '', name: 'Unknown', tournamentId: '', 
                               createdAt: DateTime.now(), updatedAt: DateTime.now()));
    final team2 = widget.teams.firstWhere((t) => t.id == game.team2Id, 
        orElse: () => TeamModel(id: '', name: 'Unknown', tournamentId: '', 
                               createdAt: DateTime.now(), updatedAt: DateTime.now()));
    final resource = widget.resources.firstWhere((r) => r.id == game.resourceId, 
        orElse: () => TournamentResourceModel(id: '', tournamentId: '', name: 'TBD', type: ''));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Match Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team1.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: groupColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'vs',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: groupColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        team2.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      resource.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      game.scheduledDate != null && game.scheduledTime != null
                          ? '${game.scheduledDate!.day}/${game.scheduledDate!.month} at ${game.scheduledTime}'
                          : 'TBD',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (game.hasResults) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      game.resultSummary!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(game.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              game.status.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStageScheduleView(List<GameModel> games) {
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

    if (schedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No scheduled games',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: sortedDates.map((dateKey) {
          return _buildDateSection(dateKey, schedule[dateKey]!);
        }).toList(),
      ),
    );
  }

  Widget _buildDateSection(String date, Map<String, List<GameModel>> timeSlots) {
    final sortedTimes = timeSlots.keys.toList()..sort();
    final totalGames = timeSlots.values.fold(0, (sum, games) => sum + games.length);
    final completedGames = timeSlots.values
        .expand((games) => games)
        .where((game) => game.status == GameStatus.completed)
        .length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header with Progress
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today, 
                    color: Theme.of(context).primaryColor, 
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      const SizedBox(height: 4),
                      Text(
                        '$totalGames games • $completedGames completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress indicator
                if (totalGames > 0) ...[
                  CircularProgressIndicator(
                    value: completedGames / totalGames,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completedGames == totalGames ? Colors.green : Theme.of(context).primaryColor,
                    ),
                    strokeWidth: 3,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(completedGames / totalGames * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: completedGames == totalGames ? Colors.green : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Time Slots
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: sortedTimes.map((time) {
                return _buildTimeSlot(time, timeSlots[time]!);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String time, List<GameModel> games) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: games.isEmpty ? Colors.grey.withOpacity(0.05) : Colors.blue.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: games.isEmpty ? Colors.grey.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    games.isEmpty ? Icons.schedule_outlined : Icons.sports_soccer,
                    size: 16,
                    color: games.isEmpty ? Colors.grey[600] : Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: games.isEmpty ? Colors.grey[600] : Colors.blue[700],
                    ),
                  ),
                ),
                if (games.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${games.length} ${games.length == 1 ? 'game' : 'games'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Games Content
          if (games.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No games scheduled',
                      style: TextStyle(
                        color: Colors.grey[600], 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: games.map((game) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCompactGroupStageGameCard(game),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupStageGameCard(GameModel game) {
    final team1 = widget.teams.firstWhere((t) => t.id == game.team1Id, 
        orElse: () => TeamModel(id: '', name: 'Unknown', tournamentId: '', 
                               createdAt: DateTime.now(), updatedAt: DateTime.now()));
    final team2 = widget.teams.firstWhere((t) => t.id == game.team2Id, 
        orElse: () => TeamModel(id: '', name: 'Unknown', tournamentId: '', 
                               createdAt: DateTime.now(), updatedAt: DateTime.now()));
    final resource = widget.resources.firstWhere((r) => r.id == game.resourceId, 
        orElse: () => TournamentResourceModel(id: '', tournamentId: '', name: 'TBD', type: ''));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${team1.name} vs ${team2.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(game.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.status.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Score Display (if game has results)
            if (game.hasResults) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          team1.name,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${game.team1Score ?? 0}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 40),
                    Column(
                      children: [
                        Text(
                          team2.name,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${game.team2Score ?? 0}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${game.scheduledDate?.day}/${game.scheduledDate?.month} at ${game.scheduledTime ?? 'TBD'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.place, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  resource.name,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (game.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                game.notes!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
            
            // Game Action Buttons
            const SizedBox(height: 12),
            _buildGameActionButtons(game),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactGroupStageGameCard(GameModel game) {
    final team1 = widget.teams.firstWhere((t) => t.id == game.team1Id, 
        orElse: () => TeamModel(id: '', name: 'Unknown', tournamentId: '', 
                               createdAt: DateTime.now(), updatedAt: DateTime.now()));
    final team2 = widget.teams.firstWhere((t) => t.id == game.team2Id, 
        orElse: () => TeamModel(id: '', name: 'Unknown', tournamentId: '', 
                               createdAt: DateTime.now(), updatedAt: DateTime.now()));
    final resource = widget.resources.firstWhere((r) => r.id == game.resourceId, 
        orElse: () => TournamentResourceModel(id: '', tournamentId: '', name: 'TBD', type: ''));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${team1.name} vs ${team2.name}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ),
              Text(
                resource.name,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(game.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  game.status.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ],
          ),
          
          // Score display for compact cards
          if (game.hasResults) ...[
            const SizedBox(height: 4),
            Text(
              '${game.team1Score ?? 0} - ${game.team2Score ?? 0}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.green,
              ),
            ),
          ],
          
          // Compact action buttons
          const SizedBox(height: 4),
          _buildCompactActionButtons(game),
        ],
      ),
    );
  }

  Widget _buildCompactActionButtons(GameModel game) {
    switch (game.status) {
      case GameStatus.scheduled:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _startGame(game),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Start', style: TextStyle(fontSize: 10)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateGameScore(game),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  minimumSize: const Size(0, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Score', style: TextStyle(fontSize: 10)),
              ),
            ),
          ],
        );
      
      case GameStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateGameScore(game),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Update', style: TextStyle(fontSize: 10)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _completeGame(game),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Complete', style: TextStyle(fontSize: 10)),
              ),
            ),
          ],
        );
      
      case GameStatus.completed:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateGameScore(game),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  minimumSize: const Size(0, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 10)),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _resetGameToScheduled(game),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  minimumSize: const Size(0, 24),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Reset', style: TextStyle(fontSize: 10)),
              ),
            ),
          ],
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split('/');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  Color _getStatusColor(GameStatus status) {
    switch (status) {
      case GameStatus.scheduled:
        return Colors.blue;
      case GameStatus.inProgress:
        return Colors.orange;
      case GameStatus.completed:
        return Colors.green;
      case GameStatus.cancelled:
        return Colors.red;
      case GameStatus.postponed:
        return Colors.grey;
      case GameStatus.forfeit:
        return Colors.purple;
    }
  }

  Widget _buildTierPlayoffStats(List<GameModel> tierPlayoffGames) {
    final scheduledGames = tierPlayoffGames.where((g) => g.status == GameStatus.scheduled).length;
    final inProgressGames = tierPlayoffGames.where((g) => g.status == GameStatus.inProgress).length;
    final completedGames = tierPlayoffGames.where((g) => g.status == GameStatus.completed).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            label: 'Total',
            value: tierPlayoffGames.length.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            label: 'Scheduled',
            value: scheduledGames.toString(),
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            label: 'In Progress',
            value: inProgressGames.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatChip(
            label: 'Completed',
            value: completedGames.toString(),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierPlayoffScheduleView(List<GameModel> tierPlayoffGames) {
    // Group games by date
    final gamesByDate = <String, List<GameModel>>{};
    for (final game in tierPlayoffGames) {
      if (game.scheduledDate != null) {
        final dateKey = _formatDate(game.scheduledDate!);
        gamesByDate.putIfAbsent(dateKey, () => []).add(game);
      }
    }

    final sortedDates = gamesByDate.keys.toList()..sort((a, b) => _parseDate(a).compareTo(_parseDate(b)));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateString = sortedDates[index];
        final games = gamesByDate[dateString]!;
        final completedGames = games.where((g) => g.status == GameStatus.completed).length;
        final progressPercentage = games.isEmpty ? 0.0 : completedGames / games.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateString,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${games.length} games',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressPercentage,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressPercentage == 1.0 ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progressPercentage * 100).round()}% completed ($completedGames/${games.length})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ...games.map((game) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCompactGroupStageGameCard(game),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTierPlayoffListView(List<GameModel> tierPlayoffGames) {
    // Group games by tier based on notes
    final gamesByTier = <String, List<GameModel>>{};
    for (final game in tierPlayoffGames) {
      String tier = 'Unknown';
      if (game.notes?.contains('Pro') == true) {
        tier = 'Pro Tier';
      } else if (game.notes?.contains('Intermediate') == true) {
        tier = 'Intermediate Tier';
      } else if (game.notes?.contains('Novice') == true) {
        tier = 'Novice Tier';
      }
      gamesByTier.putIfAbsent(tier, () => []).add(game);
    }

    return ListView(
      children: gamesByTier.entries.map((entry) {
        final tierName = entry.key;
        final games = entry.value;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getTierIcon(tierName),
                      color: _getTierColor(tierName),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tierName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTierColor(tierName),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTierColor(tierName).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getTierColor(tierName).withOpacity(0.3)),
                      ),
                      child: Text(
                        '${games.length} games',
                        style: TextStyle(
                          color: _getTierColor(tierName),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...games.map((game) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildGroupStageGameCard(game),
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getTierIcon(String tierName) {
    switch (tierName) {
      case 'Pro Tier':
        return Icons.emoji_events;
      case 'Intermediate Tier':
        return Icons.trending_up;
      case 'Novice Tier':
        return Icons.school;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTierColor(String tierName) {
    switch (tierName) {
      case 'Pro Tier':
        return Colors.amber;
      case 'Intermediate Tier':
        return Colors.blue;
      case 'Novice Tier':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Enum for tiered tournament phases
enum TieredTournamentPhase {
  setup,
  groupStage,
  tierClassification,
  tieredPlayoffs,
}

 