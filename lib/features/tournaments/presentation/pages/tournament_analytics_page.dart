import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/core/models/game_model.dart';
import 'package:teamapp3/core/models/team_model.dart';
import 'package:teamapp3/features/tournaments/data/repositories/game_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/team_repository.dart';

class TournamentAnalyticsPage extends StatefulWidget {

  const TournamentAnalyticsPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });
  final String tournamentId;
  final String tournamentName;

  @override
  State<TournamentAnalyticsPage> createState() => _TournamentAnalyticsPageState();
}

class _TournamentAnalyticsPageState extends State<TournamentAnalyticsPage>
    with SingleTickerProviderStateMixin {
  final GameRepository _gameRepository = GameRepository();
  final TeamRepository _teamRepository = TeamRepository();

  late TabController _tabController;

  // Data
  List<GameModel> _games = [];
  List<TeamModel> _teams = [];
  Map<String, TeamModel> _teamMap = {};
  Map<String, TeamAnalytics> _teamAnalytics = {};
  TournamentOverview? _overview;

  // State
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final games = await _gameRepository.getTournamentGames(widget.tournamentId);
      final teams = await _teamRepository.getTournamentTeams(widget.tournamentId);

      final teamMap = <String, TeamModel>{};
      for (final team in teams) {
        teamMap[team.id] = team;
      }

      final teamAnalytics = _calculateTeamAnalytics(games, teams);
      final overview = _calculateOverview(games, teams);

      setState(() {
        _games = games;
        _teams = teams;
        _teamMap = teamMap;
        _teamAnalytics = teamAnalytics;
        _overview = overview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, TeamAnalytics> _calculateTeamAnalytics(List<GameModel> games, List<TeamModel> teams) {
    final analytics = <String, TeamAnalytics>{};

    for (final team in teams) {
      final teamGames = games.where((g) => 
          (g.team1Id == team.id || g.team2Id == team.id) && 
          g.status == GameStatus.completed &&
          g.hasResults,).toList();

      var wins = 0;
      var losses = 0;
      var draws = 0;
      var totalPointsFor = 0;
      var totalPointsAgainst = 0;
      var totalGames = teamGames.length;
      
      final scoreMargins = <int>[];

      for (final game in teamGames) {
        final isTeam1 = game.team1Id == team.id;
        final teamScore = isTeam1 ? (game.team1Score ?? 0) : (game.team2Score ?? 0);
        final opponentScore = isTeam1 ? (game.team2Score ?? 0) : (game.team1Score ?? 0);

        totalPointsFor += teamScore;
        totalPointsAgainst += opponentScore;
        
        final margin = teamScore - opponentScore;
        scoreMargins.add(margin);

        if (game.winnerId == team.id) {
          wins++;
        } else if (game.winnerId == null) {
          draws++;
        } else {
          losses++;
        }
      }

      final winPercentage = totalGames > 0 ? wins / totalGames : 0.0;
      final avgPointsFor = totalGames > 0 ? totalPointsFor / totalGames : 0.0;
      final avgPointsAgainst = totalGames > 0 ? totalPointsAgainst / totalGames : 0.0;
      final avgMargin = scoreMargins.isNotEmpty 
          ? scoreMargins.reduce((a, b) => a + b) / scoreMargins.length 
          : 0.0;

      final biggestWin = scoreMargins.isNotEmpty 
          ? scoreMargins.reduce((a, b) => a > b ? a : b)
          : 0;
      final biggestLoss = scoreMargins.isNotEmpty 
          ? scoreMargins.reduce((a, b) => a < b ? a : b)
          : 0;

      analytics[team.id] = TeamAnalytics(
        teamId: team.id,
        teamName: team.name,
        gamesPlayed: totalGames,
        wins: wins,
        losses: losses,
        draws: draws,
        winPercentage: winPercentage,
        totalPointsFor: totalPointsFor,
        totalPointsAgainst: totalPointsAgainst,
        avgPointsFor: avgPointsFor,
        avgPointsAgainst: avgPointsAgainst,
        avgMargin: avgMargin,
        biggestWin: biggestWin,
        biggestLoss: biggestLoss,
      );
    }

    return analytics;
  }

  TournamentOverview _calculateOverview(List<GameModel> games, List<TeamModel> teams) {
    final completedGames = games.where((g) => g.status == GameStatus.completed).toList();
    final scheduledGames = games.where((g) => g.status == GameStatus.scheduled).toList();
    
    final completionRate = games.isNotEmpty ? completedGames.length / games.length : 0.0;
    
    final totalPoints = completedGames.fold<int>(0, (sum, game) => 
        sum + (game.team1Score ?? 0) + (game.team2Score ?? 0),);
    
    final avgPointsPerGame = completedGames.isNotEmpty 
        ? totalPoints / completedGames.length 
        : 0.0;

    final margins = <int>[];
    for (final game in completedGames) {
      if (game.hasResults) {
        final margin = (game.team1Score! - game.team2Score!).abs();
        margins.add(margin);
      }
    }
    
    final avgMargin = margins.isNotEmpty 
        ? margins.reduce((a, b) => a + b) / margins.length 
        : 0.0;

    return TournamentOverview(
      totalGames: games.length,
      completedGames: completedGames.length,
      scheduledGames: scheduledGames.length,
      completionRate: completionRate,
      totalTeams: teams.length,
      avgPointsPerGame: avgPointsPerGame,
      avgMargin: avgMargin,
    );
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
              'Analytics & Statistics',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.groups), text: 'Team Stats'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Rankings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTeamStatsTab(),
                _buildRankingsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_overview == null) {
      return const Center(child: Text('No overview data available'));
    }

    final overview = _overview!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverviewCards(overview),
        const SizedBox(height: 24),
        _buildTopPerformers(),
        const SizedBox(height: 24),
        _buildRecentGames(),
      ],
    );
  }

  Widget _buildOverviewCards(TournamentOverview overview) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildOverviewCard(
          'Total Games',
          '${overview.totalGames}',
          Icons.sports_soccer,
          Colors.blue,
          subtitle: '${overview.completedGames} completed',
        ),
        _buildOverviewCard(
          'Completion',
          '${(overview.completionRate * 100).toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.green,
          subtitle: '${overview.scheduledGames} remaining',
        ),
        _buildOverviewCard(
          'Avg Score',
          overview.avgPointsPerGame.toStringAsFixed(1),
          Icons.trending_up,
          Colors.orange,
          subtitle: 'points per game',
        ),
        _buildOverviewCard(
          'Competitiveness',
          overview.avgMargin.toStringAsFixed(1),
          Icons.balance,
          Colors.purple,
          subtitle: 'avg margin',
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers() {
    final sortedByWins = _teamAnalytics.values.toList()
      ..sort((a, b) => b.wins.compareTo(a.wins));
    
    final sortedByPoints = _teamAnalytics.values.toList()
      ..sort((a, b) => b.totalPointsFor.compareTo(a.totalPointsFor));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Most Wins',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      ...sortedByWins.take(3).map((team) => _buildLeaderboardItem(
                        team.teamName, 
                        '${team.wins} wins',
                        sortedByWins.indexOf(team) + 1,
                      ),),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Scorers',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      ...sortedByPoints.take(3).map((team) => _buildLeaderboardItem(
                        team.teamName, 
                        '${team.totalPointsFor} pts',
                        sortedByPoints.indexOf(team) + 1,
                      ),),
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

  Widget _buildLeaderboardItem(String teamName, String value, int position) {
    final medal = position == 1 ? '🥇' : position == 2 ? '🥈' : '🥉';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              teamName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGames() {
    final recentGames = _games
        .where((g) => g.status == GameStatus.completed)
        .toList()
      ..sort((a, b) => (b.scheduledDate ?? DateTime.now()).compareTo(a.scheduledDate ?? DateTime.now()));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (recentGames.isEmpty) ...[
              const Text('No completed games yet'),
            ] else ...[
              ...recentGames.take(5).map(_buildRecentGameItem),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGameItem(GameModel game) {
    final team1 = _teamMap[game.team1Id];
    final team2 = _teamMap[game.team2Id];
    final winner = game.winnerId != null ? _teamMap[game.winnerId!] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team1?.name ?? 'Team 1',
                        style: TextStyle(
                          fontWeight: game.winnerId == game.team1Id 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: game.winnerId == game.team1Id 
                              ? Colors.green[700] 
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      '${game.team1Score ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: game.winnerId == game.team1Id 
                            ? Colors.green[700] 
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team2?.name ?? 'Team 2',
                        style: TextStyle(
                          fontWeight: game.winnerId == game.team2Id 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: game.winnerId == game.team2Id 
                              ? Colors.green[700] 
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      '${game.team2Score ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: game.winnerId == game.team2Id 
                            ? Colors.green[700] 
                            : null,
                      ),
                    ),
                  ],
                ),
                if (winner != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Winner: ${winner.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatsTab() {
    if (_teamAnalytics.isEmpty) {
      return const Center(child: Text('No team statistics available'));
    }

    final sortedTeams = _teamAnalytics.values.toList()
      ..sort((a, b) => b.totalPointsFor.compareTo(a.totalPointsFor));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTeams.length,
      itemBuilder: (context, index) {
        final analytics = sortedTeams[index];
        return _buildTeamAnalyticsCard(analytics);
      },
    );
  }

  Widget _buildTeamAnalyticsCard(TeamAnalytics analytics) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          analytics.teamName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${analytics.wins}W-${analytics.losses}L-${analytics.draws}D • ${(analytics.winPercentage * 100).toStringAsFixed(1)}%',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatsRow('Games Played', '${analytics.gamesPlayed}'),
                _buildStatsRow('Win Percentage', '${(analytics.winPercentage * 100).toStringAsFixed(1)}%'),
                const Divider(),
                _buildStatsRow('Total Points For', '${analytics.totalPointsFor}'),
                _buildStatsRow('Total Points Against', '${analytics.totalPointsAgainst}'),
                _buildStatsRow('Point Difference', '${analytics.totalPointsFor - analytics.totalPointsAgainst}'),
                const Divider(),
                _buildStatsRow('Avg Points For', analytics.avgPointsFor.toStringAsFixed(1)),
                _buildStatsRow('Avg Points Against', analytics.avgPointsAgainst.toStringAsFixed(1)),
                _buildStatsRow('Avg Margin', analytics.avgMargin.toStringAsFixed(1)),
                const Divider(),
                _buildStatsRow('Biggest Win', '${analytics.biggestWin}'),
                _buildStatsRow('Biggest Loss', '${analytics.biggestLoss}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRankingsTab() {
    final sortedByWinPercentage = _teamAnalytics.values.toList()
      ..sort((a, b) {
        // First sort by win percentage, then by total points
        final comparison = b.winPercentage.compareTo(a.winPercentage);
        return comparison != 0 ? comparison : b.totalPointsFor.compareTo(a.totalPointsFor);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedByWinPercentage.length,
      itemBuilder: (context, index) {
        final analytics = sortedByWinPercentage[index];
        final position = index + 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: position <= 3 
                  ? (position == 1 ? Colors.amber : position == 2 ? Colors.grey : Colors.brown[300])
                  : Colors.blue,
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              analytics.teamName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${analytics.wins}W-${analytics.losses}L-${analytics.draws}D',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(analytics.winPercentage * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${analytics.totalPointsFor} pts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Data models
class TeamAnalytics {

  TeamAnalytics({
    required this.teamId,
    required this.teamName,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winPercentage,
    required this.totalPointsFor,
    required this.totalPointsAgainst,
    required this.avgPointsFor,
    required this.avgPointsAgainst,
    required this.avgMargin,
    required this.biggestWin,
    required this.biggestLoss,
  });
  final String teamId;
  final String teamName;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final double winPercentage;
  final int totalPointsFor;
  final int totalPointsAgainst;
  final double avgPointsFor;
  final double avgPointsAgainst;
  final double avgMargin;
  final int biggestWin;
  final int biggestLoss;
}

class TournamentOverview {

  TournamentOverview({
    required this.totalGames,
    required this.completedGames,
    required this.scheduledGames,
    required this.completionRate,
    required this.totalTeams,
    required this.avgPointsPerGame,
    required this.avgMargin,
  });
  final int totalGames;
  final int completedGames;
  final int scheduledGames;
  final double completionRate;
  final int totalTeams;
  final double avgPointsPerGame;
  final double avgMargin;
} 