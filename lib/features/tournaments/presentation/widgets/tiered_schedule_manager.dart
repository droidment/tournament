import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _phaseTabController = TabController(length: 4, vsync: this);
    _initializeTournamentState();
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
      
      // Determine current phase
      _currentPhase = _determineCurrentPhase();
      
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
    final groupStageGames = widget.existingGames.where((game) =>
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
    final tierPlayoffGames = widget.existingGames.where((game) =>
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
        _buildPhaseIndicator(),
        const SizedBox(height: 16),
        _buildPhaseTabBar(),
        const SizedBox(height: 16),
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

  Widget _buildPhaseIndicator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPhaseIcon(_currentPhase),
                  color: _getPhaseColor(_currentPhase),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Current Phase: ${_getPhaseDisplayName(_currentPhase)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getPhaseDescription(_currentPhase),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            if (_structure != null) ...[
              const SizedBox(height: 12),
              _buildTournamentStructureInfo(),
            ],
          ],
        ),
      ),
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
    final groupStageGames = widget.existingGames.where((game) =>
      game.notes?.contains('Group Stage') == true ||
      game.roundName?.contains('Group') == true
    ).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Stage Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (groupStageGames.isEmpty) ...[
              const Text('No group stage games scheduled yet.'),
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
              Text('${groupStageGames.length} group stage games scheduled'),
              const SizedBox(height: 8),
              Text(
                'Completed: ${groupStageGames.where((g) => g.status == GameStatus.completed).length}/${groupStageGames.length}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              // Add detailed group stage game display here
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTierClassificationContent() {
    // Check if group stage is complete
    final groupStageGames = widget.existingGames.where((game) =>
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

    final tierPlayoffGames = widget.existingGames.where((game) =>
      game.notes?.contains('Tier') == true ||
      game.roundName?.contains('Elimination') == true
    ).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tiered Playoff Brackets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              Text('${tierPlayoffGames.length} playoff games scheduled'),
              // Add detailed playoff bracket display here
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

  Future<void> _calculateTierAssignments() async {
    setState(() => _isGeneratingSchedule = true);
    
    try {
      final completedGames = widget.existingGames.where((g) => g.status == GameStatus.completed).toList();
      
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
    int gameDuration = 60;
    int timeBetweenGames = 15;
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Parameters'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              ListTile(
                leading: const Icon(Icons.timer),
                title: Text('Game Duration: ${gameDuration}min'),
                subtitle: Slider(
                  value: gameDuration.toDouble(),
                  min: 30,
                  max: 180,
                  divisions: 15,
                  onChanged: (value) => setDialogState(() => gameDuration = value.round()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.pause),
                title: Text('Break Between Games: ${timeBetweenGames}min'),
                subtitle: Slider(
                  value: timeBetweenGames.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: (value) => setDialogState(() => timeBetweenGames = value.round()),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop({
                'startDate': startDate,
                'gameDuration': gameDuration,
                'timeBetweenGames': timeBetweenGames,
              }),
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
}

// Enum for tiered tournament phases
enum TieredTournamentPhase {
  setup,
  groupStage,
  tierClassification,
  tieredPlayoffs,
}

 