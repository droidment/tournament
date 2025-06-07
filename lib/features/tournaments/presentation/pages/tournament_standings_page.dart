import 'package:flutter/material.dart';
import 'package:teamapp3/core/models/tournament_standings_model.dart';
import 'package:teamapp3/core/models/team_model.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/tournament_standings_widget.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';
import 'package:teamapp3/features/tournaments/data/repositories/team_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_repository.dart';
import 'package:teamapp3/features/tournaments/data/services/tournament_standings_service.dart';
import 'package:teamapp3/features/tournaments/data/services/live_score_service.dart';

class TournamentStandingsPage extends StatefulWidget {

  const TournamentStandingsPage({
    super.key,
    required this.tournamentId,
  });
  final String tournamentId;

  @override
  State<TournamentStandingsPage> createState() => _TournamentStandingsPageState();
}

class _TournamentStandingsPageState extends State<TournamentStandingsPage> {
  // Repositories and services
  final TournamentRepository _tournamentRepository = TournamentRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final LiveScoreService _liveScoreService = LiveScoreService();

  // State
  TournamentModel? _tournament;
  List<TeamModel> _teams = [];
  TournamentStandingsModel? _standings;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToLiveUpdates();
  }

  @override
  void dispose() {
    _liveScoreService.unsubscribeFromTournament(widget.tournamentId);
    _liveScoreService.dispose();
    super.dispose();
  }

  /// Load tournament data and calculate standings
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load tournament and teams in parallel
      final futures = await Future.wait([
        _tournamentRepository.getTournament(widget.tournamentId),
        _teamRepository.getTournamentTeams(widget.tournamentId),
      ]);

      final tournament = futures[0] as TournamentModel?;
      final teams = futures[1]! as List<TeamModel>;

      if (tournament == null) {
        throw Exception('Tournament not found');
      }

      // Calculate standings
      final standings = await _liveScoreService.getTournamentStandings(
        tournamentId: widget.tournamentId,
        format: tournament.format,
        teams: teams,
      );

      setState(() {
        _tournament = tournament;
        _teams = teams;
        _standings = standings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Subscribe to live standings updates
  void _subscribeToLiveUpdates() {
    _liveScoreService.subscribeToTournament(widget.tournamentId);
    
    // Listen to standings updates
    _liveScoreService.standingsStream.listen((standings) {
      if (standings.tournamentId == widget.tournamentId && mounted) {
        setState(() {
          _standings = standings;
        });
      }
    });
  }

  /// Refresh standings data
  Future<void> _refreshStandings() async {
    if (_tournament == null) return;

    try {
      final standings = await _liveScoreService.getTournamentStandings(
        tournamentId: widget.tournamentId,
        format: _tournament!.format,
        teams: _teams,
        forceRefresh: true,
      );

      setState(() {
        _standings = standings;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Standings refreshed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing standings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament?.name ?? 'Tournament Standings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_standings != null)
            IconButton(
              onPressed: _refreshStandings,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Standings',
            ),
          IconButton(
            onPressed: _showStandingsInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Standings Info',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading tournament standings...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading standings',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tournament != null && _standings != null
                  ? RefreshIndicator(
                      onRefresh: _refreshStandings,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTournamentHeader(),
                            const SizedBox(height: 16),
                            TournamentStandingsWidget(
                              standings: _standings!,
                              format: _tournament!.format,
                              onRefresh: _refreshStandings,
                            ),
                            const SizedBox(height: 16),
                            _buildStandingsLegend(),
                          ],
                        ),
                      ),
                    )
                  : const Center(
                      child: Text('No tournament data available'),
                    ),
    );
  }

  Widget _buildTournamentHeader() {
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
                    _tournament!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_tournament!.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusDisplayName(_tournament!.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.sports,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _getFormatDisplayName(_tournament!.format),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.people,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${_teams.length} teams',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (_tournament!.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _tournament!.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStandingsLegend() {
    if (_standings == null) return const SizedBox.shrink();

    final format = _standings!.format;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (format == 'round_robin') ...[
              _buildLegendItem('Pts', 'Tournament Points (3 for win, 1 for draw)'),
              _buildLegendItem('W-L-D', 'Wins-Losses-Draws'),
              _buildLegendItem('PF', 'Points For (total points scored)'),
              _buildLegendItem('PA', 'Points Against (total points conceded)'),
              _buildLegendItem('PD', 'Point Difference (+/-)'),
            ] else if (format == 'single_elimination' || format == 'double_elimination') ...[
              _buildLegendItem('Status', 'Current tournament status'),
              _buildLegendItem('W-L', 'Wins-Losses in tournament'),
              _buildLegendItem('🏆', 'Tournament Champion'),
              _buildLegendItem('🥈', 'Runner-up / Finalist'),
              _buildLegendItem('🥉', 'Semifinalist'),
            ] else if (format == 'swiss') ...[
              _buildLegendItem('MP', 'Match Points (1 for win, 0.5 for draw)'),
              _buildLegendItem('TB', 'Tie-Break (Buchholz score)'),
              _buildLegendItem('W-L-D', 'Wins-Losses-Draws'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String term, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              term,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showStandingsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Standings Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Format: ${_getFormatDisplayName(_tournament!.format)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_tournament!.format == TournamentFormat.roundRobin) ...[
                const Text('In Round Robin tournaments:'),
                const Text('• Every team plays every other team once'),
                const Text('• Teams are ranked by tournament points'),
                const Text('• Tie-breakers: Point difference, then points for'),
              ] else if (_tournament!.format == TournamentFormat.singleElimination) ...[
                const Text('In Single Elimination tournaments:'),
                const Text('• Teams are eliminated after one loss'),
                const Text('• Winner advances, loser is eliminated'),
                const Text('• Rankings based on elimination round'),
              ] else if (_tournament!.format == TournamentFormat.doubleElimination) ...[
                const Text('In Double Elimination tournaments:'),
                const Text('• Teams must lose twice to be eliminated'),
                const Text('• Winners and losers brackets'),
                const Text('• More forgiving than single elimination'),
              ] else if (_tournament!.format == TournamentFormat.swiss) ...[
                const Text('In Swiss System tournaments:'),
                const Text('• Teams play a fixed number of rounds'),
                const Text('• Paired based on current standings'),
                const Text("• Tie-breaker: Buchholz score (opponents' points)"),
              ],
              const SizedBox(height: 16),
              Text(
                'Live Updates: ${_standings?.lastUpdated != null ? 'Enabled' : 'Disabled'}',
                style: TextStyle(
                  color: _standings?.lastUpdated != null ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
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

  // Helper methods
  String _getFormatDisplayName(TournamentFormat format) {
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

  String _getStatusDisplayName(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.draft:
        return 'Draft';
      case TournamentStatus.registration:
        return 'Registration';
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
        return Colors.green;
      case TournamentStatus.completed:
        return Colors.purple;
      case TournamentStatus.cancelled:
        return Colors.red;
    }
  }
} 