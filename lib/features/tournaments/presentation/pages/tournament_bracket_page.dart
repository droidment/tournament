import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/game_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/tournament_resource_model.dart';
import '../../../../core/models/tournament_bracket_model.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/repositories/tournament_resource_repository.dart';
import '../../data/services/bracket_generator_service.dart';
import '../widgets/tournament_bracket_widget.dart';
import '../widgets/generate_bracket_dialog.dart';

class TournamentBracketPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentBracketPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<TournamentBracketPage> createState() => _TournamentBracketPageState();
}

class _TournamentBracketPageState extends State<TournamentBracketPage>
    with SingleTickerProviderStateMixin {
  final GameRepository _gameRepository = GameRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final TournamentResourceRepository _resourceRepository = TournamentResourceRepository();
  final BracketGeneratorService _bracketService = BracketGeneratorService();

  late TabController _tabController;
  
  // Data
  TournamentBracketModel? _bracket;
  List<TeamModel> _teams = [];
  List<TournamentResourceModel> _resources = [];
  List<GameModel> _bracketGames = [];
  Map<String, TeamModel> _teamMap = {};
  
  // State
  bool _isLoading = true;
  bool _isGenerating = false;
  String _selectedFormat = 'single_elimination';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBracketData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBracketData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load teams, resources, and bracket games
      final teams = await _teamRepository.getTournamentTeams(widget.tournamentId);
      final resources = await _resourceRepository.getTournamentResources(widget.tournamentId);
      final games = await _gameRepository.getTournamentGames(widget.tournamentId);
      
      // Filter bracket games (games with round information)
      final bracketGames = games.where((game) => game.round != null).toList();
      
      // Create team map
      final teamMap = <String, TeamModel>{};
      for (final team in teams) {
        teamMap[team.id] = team;
      }
      
      // Try to reconstruct bracket from existing games
      TournamentBracketModel? bracket;
      if (bracketGames.isNotEmpty) {
        bracket = await _reconstructBracketFromGames(bracketGames, teams);
      }
      
      setState(() {
        _teams = teams;
        _resources = resources;
        _bracketGames = bracketGames;
        _teamMap = teamMap;
        _bracket = bracket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bracket data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<TournamentBracketModel?> _reconstructBracketFromGames(
    List<GameModel> games,
    List<TeamModel> teams,
  ) async {
    try {
      // Group games by round
      final gamesByRound = <int, List<GameModel>>{};
      for (final game in games) {
        if (game.round != null) {
          gamesByRound.putIfAbsent(game.round!, () => []).add(game);
        }
      }
      
      if (gamesByRound.isEmpty) return null;
      
      // Create bracket rounds
      final rounds = <BracketRoundModel>[];
      final sortedRounds = gamesByRound.keys.toList()..sort();
      
      for (final roundNumber in sortedRounds) {
        final roundGames = gamesByRound[roundNumber]!;
        final matches = <BracketMatchModel>[];
        
        for (int i = 0; i < roundGames.length; i++) {
          final game = roundGames[i];
          matches.add(BracketMatchModel(
            matchNumber: i + 1,
            position: i + 1,
            team1Id: game.team1Id,
            team2Id: game.team2Id,
            winnerId: game.winnerId,
            team1Score: game.team1Score,
            team2Score: game.team2Score,
            gameId: game.id,
            isComplete: game.status == GameStatus.completed,
            scheduledDateTime: game.scheduledDate != null && game.scheduledTime != null
                ? DateTime.parse('${game.scheduledDate!.toIso8601String().split('T')[0]} ${game.scheduledTime}')
                : null,
          ));
        }
        
        rounds.add(BracketRoundModel(
          roundNumber: roundNumber,
          roundName: _getRoundName(roundNumber, sortedRounds.length),
          matches: matches,
          isComplete: matches.every((m) => m.isComplete),
        ));
      }
      
      // Determine bracket format based on structure
      final format = _determineBracketFormat(rounds, teams.length);
      
      return TournamentBracketModel(
        tournamentId: widget.tournamentId,
        format: format,
        rounds: rounds,
        isComplete: rounds.every((r) => r.isComplete),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error reconstructing bracket: $e');
      return null;
    }
  }

  String _getRoundName(int round, int totalRounds) {
    final remainingRounds = totalRounds - round + 1;
    if (remainingRounds == 1) return 'Final';
    if (remainingRounds == 2) return 'Semifinal';
    if (remainingRounds == 3) return 'Quarterfinal';
    if (remainingRounds == 4) return 'Round of 16';
    if (remainingRounds == 5) return 'Round of 32';
    return 'Round $round';
  }

  String _determineBracketFormat(List<BracketRoundModel> rounds, int teamCount) {
    // Simple heuristic to determine bracket format
    final totalGames = rounds.fold<int>(0, (sum, round) => sum + round.matches.length);
    final singleEliminationGames = teamCount > 1 ? teamCount - 1 : 0;
    
    if (totalGames > singleEliminationGames * 1.5) {
      return 'double_elimination';
    } else {
      return 'single_elimination';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tournamentName),
            Text(
              'Tournament Bracket',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree), text: 'Bracket'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Results'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
        actions: [
          if (_bracket != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBracketData,
              tooltip: 'Refresh Bracket',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'export':
                    _exportBracket();
                    break;
                  case 'fullscreen':
                    _openFullscreenBracket();
                    break;
                  case 'print':
                    _printBracket();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Export Bracket'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'fullscreen',
                  child: Row(
                    children: [
                      Icon(Icons.fullscreen),
                      SizedBox(width: 8),
                      Text('Fullscreen View'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('Print Bracket'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBracketTab(),
                _buildResultsTab(),
                _buildSettingsTab(),
              ],
            ),
      floatingActionButton: _bracket == null && _teams.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showGenerateBracketDialog(),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Generate Bracket'),
            )
          : null,
    );
  }

  Widget _buildBracketTab() {
    if (_bracket == null) {
      return _buildNoBracketState();
    }

    return Column(
      children: [
        _buildBracketHeader(),
        Expanded(
          child: TournamentBracketWidget(
            bracket: _bracket!,
            teamMap: _teamMap,
            onMatchTap: _handleMatchTap,
            showScores: true,
            isInteractive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildBracketHeader() {
    if (_bracket == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBracketTitle(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getBracketSubtitle(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildBracketStats(),
        ],
      ),
    );
  }

  Widget _buildBracketStats() {
    if (_bracket == null) return const SizedBox.shrink();

    final totalMatches = _bracket!.rounds.fold<int>(0, (sum, round) => sum + round.matches.length);
    final completedMatches = _bracket!.rounds.fold<int>(0, (sum, round) => 
        sum + round.matches.where((m) => m.isComplete).length);
    final progress = totalMatches > 0 ? completedMatches / totalMatches : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$completedMatches / $totalMatches',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Matches Complete',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
            ),
          ),
        ),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildResultsTab() {
    if (_bracket == null) {
      return const Center(
        child: Text('No bracket results available'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bracket Results',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._bracket!.rounds.map((round) => _buildRoundResults(round)),
      ],
    );
  }

  Widget _buildRoundResults(BracketRoundModel round) {
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
                  round.isComplete ? Icons.check_circle : Icons.schedule,
                  color: round.isComplete ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  round.roundName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${round.completedMatchesCount}/${round.totalMatchesCount}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...round.matches.map((match) => _buildMatchResult(match)),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchResult(BracketMatchModel match) {
    final team1 = _teamMap[match.team1Id];
    final team2 = _teamMap[match.team2Id];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: match.isComplete ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: match.isComplete ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.isBye ? 'BYE' : 'Match ${match.matchNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                if (!match.isBye) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          team1?.name ?? 'TBD',
                          style: TextStyle(
                            fontWeight: match.winnerId == match.team1Id 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: match.winnerId == match.team1Id 
                                ? Colors.green[700] 
                                : null,
                          ),
                        ),
                      ),
                      if (match.hasResults) ...[
                        Text(
                          '${match.team1Score}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: match.winnerId == match.team1Id 
                                ? Colors.green[700] 
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          team2?.name ?? 'TBD',
                          style: TextStyle(
                            fontWeight: match.winnerId == match.team2Id 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: match.winnerId == match.team2Id 
                                ? Colors.green[700] 
                                : null,
                          ),
                        ),
                      ),
                      if (match.hasResults) ...[
                        Text(
                          '${match.team2Score}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: match.winnerId == match.team2Id 
                                ? Colors.green[700] 
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  Text(
                    '${team1?.name ?? 'Team'} advances',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            match.isComplete 
                ? Icons.check_circle 
                : match.hasTeams 
                    ? Icons.schedule 
                    : Icons.help_outline,
            color: match.isComplete 
                ? Colors.green 
                : match.hasTeams 
                    ? Colors.orange 
                    : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bracket Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_bracket != null) ...[
          _buildSettingsCard(
            title: 'Current Bracket',
            children: [
              _buildSettingsRow('Format', _getBracketFormatName(_bracket!.format)),
              _buildSettingsRow('Total Rounds', '${_bracket!.totalRounds}'),
              _buildSettingsRow('Status', _bracket!.isComplete ? 'Complete' : 'In Progress'),
              _buildSettingsRow('Created', _formatDateTime(_bracket!.createdAt)),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionsCard(),
        ] else ...[
          _buildSettingsCard(
            title: 'Tournament Info',
            children: [
              _buildSettingsRow('Teams', '${_teams.length}'),
              _buildSettingsRow('Resources', '${_resources.length}'),
              _buildSettingsRow('Bracket Games', '${_bracketGames.length}'),
            ],
          ),
          const SizedBox(height: 16),
          _buildGenerateBracketCard(),
        ],
      ],
    );
  }

  Widget _buildNoBracketState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Tournament Bracket',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _teams.isEmpty 
                ? 'Add teams to generate a tournament bracket'
                : 'Generate a bracket to start the elimination rounds',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          if (_teams.isNotEmpty) ...[
            ElevatedButton.icon(
              onPressed: () => _showGenerateBracketDialog(),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Generate Bracket'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.group_add),
              label: const Text('Add Teams First'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Refresh Bracket'),
              subtitle: const Text('Reload bracket data from server'),
              onTap: _loadBracketData,
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('Export Bracket'),
              subtitle: const Text('Export bracket as image or PDF'),
              onTap: _exportBracket,
            ),
            ListTile(
              leading: const Icon(Icons.fullscreen, color: Colors.purple),
              title: const Text('Fullscreen View'),
              subtitle: const Text('View bracket in fullscreen mode'),
              onTap: _openFullscreenBracket,
            ),
            if (!_bracket!.isComplete) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Reset Bracket'),
                subtitle: const Text('Delete current bracket and start over'),
                onTap: _showResetBracketDialog,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateBracketCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate Bracket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create a tournament bracket for elimination rounds.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _teams.length >= 2 ? () => _showGenerateBracketDialog() : null,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Generate Bracket'),
                  ),
                ),
              ],
            ),
            if (_teams.length < 2) ...[
              const SizedBox(height: 8),
              Text(
                'Need at least 2 teams to generate a bracket',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMatchTap(BracketMatchModel match) {
    if (!match.hasTeams || match.isComplete) return;

    // Find the corresponding game
    final game = _bracketGames.firstWhere(
      (g) => g.team1Id == match.team1Id && g.team2Id == match.team2Id,
      orElse: () => throw StateError('Game not found for match'),
    );

    // Show game details dialog or navigate to game management
    _showMatchDetailsDialog(match, game);
  }

  void _showMatchDetailsDialog(BracketMatchModel match, GameModel game) {
    final team1 = _teamMap[match.team1Id];
    final team2 = _teamMap[match.team2Id];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Match ${match.matchNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${team1?.name ?? 'TBD'} vs ${team2?.name ?? 'TBD'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (game.scheduledDate != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text('Date: ${game.scheduledDate!.toLocal().toString().split(' ')[0]}'),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (game.scheduledTime != null) ...[
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text('Time: ${game.scheduledTime}'),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                const Icon(Icons.info, size: 16),
                const SizedBox(width: 8),
                Text('Status: ${game.status.name}'),
              ],
            ),
            if (match.hasResults) ...[
              const SizedBox(height: 16),
              const Text(
                'Final Score:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${team1?.name}: ${match.team1Score}'),
              Text('${team2?.name}: ${match.team2Score}'),
              const SizedBox(height: 8),
              Text(
                'Winner: ${_teamMap[match.winnerId]?.name ?? 'Unknown'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!match.isComplete && match.hasTeams) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to game management or show score entry
                _showScoreEntryDialog(match, game);
              },
              child: const Text('Enter Score'),
            ),
          ],
        ],
      ),
    );
  }

  void _showScoreEntryDialog(BracketMatchModel match, GameModel game) {
    // This would implement score entry for bracket matches
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Score entry for bracket matches coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showGenerateBracketDialog() {
    showDialog(
      context: context,
      builder: (context) => GenerateBracketDialog(
        tournamentId: widget.tournamentId,
        teams: _teams,
        resources: _resources,
        onBracketGenerated: (bracket) {
          setState(() {
            _bracket = bracket;
          });
          _loadBracketData(); // Reload to get the created games
        },
      ),
    );
  }

  void _showResetBracketDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Reset Bracket'),
          ],
        ),
        content: const Text(
          'Are you sure you want to reset the bracket? This will delete all bracket games and results. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetBracket();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetBracket() async {
    try {
      // Delete all bracket games
      for (final game in _bracketGames) {
        await _gameRepository.deleteGame(game.id);
      }

      setState(() {
        _bracket = null;
        _bracketGames = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bracket reset successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting bracket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _exportBracket() {
    // Placeholder for bracket export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bracket export functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _openFullscreenBracket() {
    // Placeholder for fullscreen bracket view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fullscreen bracket view coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _printBracket() {
    // Placeholder for bracket printing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bracket printing functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Helper methods
  String _getBracketTitle() {
    if (_bracket == null) return 'No Bracket';
    return _getBracketFormatName(_bracket!.format);
  }

  String _getBracketSubtitle() {
    if (_bracket == null) return '';
    return '${_teams.length} teams • ${_bracket!.totalRounds} rounds';
  }

  String _getBracketFormatName(String format) {
    switch (format) {
      case 'single_elimination':
        return 'Single Elimination';
      case 'double_elimination':
        return 'Double Elimination';
      case 'swiss':
        return 'Swiss System';
      default:
        return format.replaceAll('_', ' ').split(' ').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return '${dateTime.toLocal().toString().split(' ')[0]} ${dateTime.toLocal().toString().split(' ')[1].substring(0, 5)}';
  }
} 