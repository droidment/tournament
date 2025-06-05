import 'dart:math';
import '../../../../core/models/tournament_standings_model.dart';
import '../../../../core/models/game_model.dart';
import '../../../../core/models/team_model.dart';
import '../models/tournament_model.dart';

class TournamentStandingsService {
  
  /// Calculate tournament standings based on games and format
  static TournamentStandingsModel calculateStandings({
    required String tournamentId,
    required TournamentFormat format,
    required List<GameModel> games,
    required List<TeamModel> teams,
    String? phase,
    bool isFinal = false,
  }) {
    switch (format) {
      case TournamentFormat.roundRobin:
        return _calculateRoundRobinStandings(
          tournamentId: tournamentId,
          games: games,
          teams: teams,
          phase: phase,
          isFinal: isFinal,
        );
      case TournamentFormat.singleElimination:
        return _calculateEliminationStandings(
          tournamentId: tournamentId,
          games: games,
          teams: teams,
          isDouble: false,
          phase: phase,
          isFinal: isFinal,
        );
      case TournamentFormat.doubleElimination:
        return _calculateEliminationStandings(
          tournamentId: tournamentId,
          games: games,
          teams: teams,
          isDouble: true,
          phase: phase,
          isFinal: isFinal,
        );
      case TournamentFormat.swiss:
        return _calculateSwissStandings(
          tournamentId: tournamentId,
          games: games,
          teams: teams,
          phase: phase,
          isFinal: isFinal,
        );
      case TournamentFormat.custom:
        // For custom tournaments, use round robin logic as default
        return _calculateRoundRobinStandings(
          tournamentId: tournamentId,
          games: games,
          teams: teams,
          phase: phase,
          isFinal: isFinal,
        );
    }
  }

  /// Calculate Round Robin standings
  static TournamentStandingsModel _calculateRoundRobinStandings({
    required String tournamentId,
    required List<GameModel> games,
    required List<TeamModel> teams,
    String? phase,
    bool isFinal = false,
  }) {
    final Map<String, _TeamStats> teamStats = {};
    
    // Initialize team stats
    for (final team in teams) {
      teamStats[team.id] = _TeamStats(
        teamId: team.id,
        teamName: team.name,
      );
    }
    
    // Process completed games
    final completedGames = games.where((game) => 
        game.status == GameStatus.completed && 
        game.hasResults && 
        game.hasTeams).toList();
    
    for (final game in completedGames) {
      final team1Stats = teamStats[game.team1Id!];
      final team2Stats = teamStats[game.team2Id!];
      
      if (team1Stats == null || team2Stats == null) continue;
      
      final team1Score = game.team1Score!;
      final team2Score = game.team2Score!;
      
      // Update games played
      team1Stats.gamesPlayed++;
      team2Stats.gamesPlayed++;
      
      // Update scores
      team1Stats.pointsFor += team1Score;
      team1Stats.pointsAgainst += team2Score;
      team2Stats.pointsFor += team2Score;
      team2Stats.pointsAgainst += team1Score;
      
      // Update wins/losses/draws and points
      if (team1Score > team2Score) {
        // Team 1 wins
        team1Stats.wins++;
        team1Stats.points += 3; // 3 points for win
        team2Stats.losses++;
        // 0 points for loss
      } else if (team2Score > team1Score) {
        // Team 2 wins
        team2Stats.wins++;
        team2Stats.points += 3; // 3 points for win
        team1Stats.losses++;
        // 0 points for loss
      } else {
        // Draw
        team1Stats.draws++;
        team1Stats.points += 1; // 1 point for draw
        team2Stats.draws++;
        team2Stats.points += 1; // 1 point for draw
      }
    }
    
    // Calculate derived stats and convert to standings
    final standings = teamStats.values.map((stats) {
      final pointsDifference = stats.pointsFor - stats.pointsAgainst;
      final winPercentage = stats.gamesPlayed > 0 
          ? stats.wins / stats.gamesPlayed 
          : 0.0;
      
      return TeamStandingModel(
        teamId: stats.teamId,
        teamName: stats.teamName,
        position: 0, // Will be set after sorting
        wins: stats.wins,
        losses: stats.losses,
        draws: stats.draws,
        gamesPlayed: stats.gamesPlayed,
        pointsFor: stats.pointsFor,
        pointsAgainst: stats.pointsAgainst,
        pointsDifference: pointsDifference,
        winPercentage: winPercentage,
                 points: stats.points.round(),
        status: 'active',
        isEliminated: false,
      );
    }).toList();
    
    // Sort by tournament points, then by point difference, then by points for
    standings.sort((a, b) {
      // Primary: Tournament points (more is better)
      if (a.points != b.points) return b.points.compareTo(a.points);
      
      // Secondary: Point difference (more is better)
      if (a.pointsDifference != b.pointsDifference) {
        return b.pointsDifference.compareTo(a.pointsDifference);
      }
      
      // Tertiary: Points for (more is better)
      if (a.pointsFor != b.pointsFor) return b.pointsFor.compareTo(a.pointsFor);
      
      // Quaternary: Fewer points against (less is better)
      return a.pointsAgainst.compareTo(b.pointsAgainst);
    });
    
    // Set positions
    for (int i = 0; i < standings.length; i++) {
      standings[i] = standings[i].copyWith(position: i + 1);
    }
    
    return TournamentStandingsModel(
      tournamentId: tournamentId,
      teamStandings: standings,
      format: 'round_robin',
      lastUpdated: DateTime.now(),
      phase: phase ?? 'round_robin',
      isFinal: isFinal,
    );
  }

  /// Calculate Elimination Tournament standings
  static TournamentStandingsModel _calculateEliminationStandings({
    required String tournamentId,
    required List<GameModel> games,
    required List<TeamModel> teams,
    required bool isDouble,
    String? phase,
    bool isFinal = false,
  }) {
    final Map<String, _TeamStats> teamStats = {};
    final Map<String, String> eliminationRounds = {};
    
    // Initialize team stats
    for (final team in teams) {
      teamStats[team.id] = _TeamStats(
        teamId: team.id,
        teamName: team.name,
      );
    }
    
    // Process completed games
    final completedGames = games.where((game) => 
        game.status == GameStatus.completed && 
        game.hasResults && 
        game.hasTeams).toList();
    
    // Sort games by round to process in order
    completedGames.sort((a, b) => (a.round ?? 0).compareTo(b.round ?? 0));
    
    for (final game in completedGames) {
      final team1Stats = teamStats[game.team1Id!];
      final team2Stats = teamStats[game.team2Id!];
      
      if (team1Stats == null || team2Stats == null) continue;
      
      final team1Score = game.team1Score!;
      final team2Score = game.team2Score!;
      
      // Update games played and scores
      team1Stats.gamesPlayed++;
      team2Stats.gamesPlayed++;
      team1Stats.pointsFor += team1Score;
      team1Stats.pointsAgainst += team2Score;
      team2Stats.pointsFor += team2Score;
      team2Stats.pointsAgainst += team1Score;
      
      // Determine winner and update elimination status
      String? eliminatedTeamId;
      String? winnerTeamId;
      
      if (team1Score > team2Score) {
        team1Stats.wins++;
        team2Stats.losses++;
        eliminatedTeamId = game.team2Id!;
        winnerTeamId = game.team1Id!;
      } else if (team2Score > team1Score) {
        team2Stats.wins++;
        team1Stats.losses++;
        eliminatedTeamId = game.team1Id!;
        winnerTeamId = game.team2Id!;
      }
      
      // In elimination tournaments, track elimination rounds
      if (eliminatedTeamId != null && !eliminationRounds.containsKey(eliminatedTeamId)) {
        final roundName = game.roundName ?? 'Round ${game.round}';
        eliminationRounds[eliminatedTeamId] = roundName;
      }
    }
    
    // Convert to standings
    final standings = teamStats.values.map((stats) {
      final pointsDifference = stats.pointsFor - stats.pointsAgainst;
      final winPercentage = stats.gamesPlayed > 0 
          ? stats.wins / stats.gamesPlayed 
          : 0.0;
      
      final isEliminated = eliminationRounds.containsKey(stats.teamId);
      final eliminatedIn = eliminationRounds[stats.teamId];
      
      // Determine status based on elimination and performance
      String status = 'active';
      if (isEliminated) {
        status = _getEliminationStatus(eliminatedIn);
      } else if (isFinal && stats.wins > 0) {
        // Tournament is complete, determine final status for active teams
        if (stats.losses == 0) {
          status = 'champion';
        } else {
          status = 'finalist';
        }
      }
      
      return TeamStandingModel(
        teamId: stats.teamId,
        teamName: stats.teamName,
        position: 0, // Will be set after sorting
        wins: stats.wins,
        losses: stats.losses,
        draws: stats.draws,
        gamesPlayed: stats.gamesPlayed,
        pointsFor: stats.pointsFor,
        pointsAgainst: stats.pointsAgainst,
        pointsDifference: pointsDifference,
        winPercentage: winPercentage,
        points: stats.wins * 3, // 3 points per win
        status: status,
        eliminatedIn: eliminatedIn,
        isEliminated: isEliminated,
      );
    }).toList();
    
    // Sort elimination standings by performance and elimination round
    standings.sort((a, b) {
      // Active teams come first
      if (a.isEliminated != b.isEliminated) {
        return a.isEliminated ? 1 : -1;
      }
      
      // If both eliminated, sort by when they were eliminated (later rounds = better)
      if (a.isEliminated && b.isEliminated) {
        final aRoundValue = _getEliminationRoundValue(a.eliminatedIn);
        final bRoundValue = _getEliminationRoundValue(b.eliminatedIn);
        if (aRoundValue != bRoundValue) return bRoundValue.compareTo(aRoundValue);
      }
      
      // Sort by wins, then by point difference
      if (a.wins != b.wins) return b.wins.compareTo(a.wins);
      if (a.pointsDifference != b.pointsDifference) {
        return b.pointsDifference.compareTo(a.pointsDifference);
      }
      return b.pointsFor.compareTo(a.pointsFor);
    });
    
    // Set positions
    for (int i = 0; i < standings.length; i++) {
      standings[i] = standings[i].copyWith(position: i + 1);
    }
    
    return TournamentStandingsModel(
      tournamentId: tournamentId,
      teamStandings: standings,
      format: isDouble ? 'double_elimination' : 'single_elimination',
      lastUpdated: DateTime.now(),
      phase: phase ?? 'elimination',
      isFinal: isFinal,
    );
  }

  /// Calculate Swiss System standings
  static TournamentStandingsModel _calculateSwissStandings({
    required String tournamentId,
    required List<GameModel> games,
    required List<TeamModel> teams,
    String? phase,
    bool isFinal = false,
  }) {
    final Map<String, _TeamStats> teamStats = {};
    final Map<String, List<String>> opponentHistory = {};
    
    // Initialize team stats
    for (final team in teams) {
      teamStats[team.id] = _TeamStats(
        teamId: team.id,
        teamName: team.name,
      );
      opponentHistory[team.id] = [];
    }
    
    // Process completed games
    final completedGames = games.where((game) => 
        game.status == GameStatus.completed && 
        game.hasResults && 
        game.hasTeams).toList();
    
    for (final game in completedGames) {
      final team1Stats = teamStats[game.team1Id!];
      final team2Stats = teamStats[game.team2Id!];
      
      if (team1Stats == null || team2Stats == null) continue;
      
      final team1Score = game.team1Score!;
      final team2Score = game.team2Score!;
      
      // Update games played and scores
      team1Stats.gamesPlayed++;
      team2Stats.gamesPlayed++;
      team1Stats.pointsFor += team1Score;
      team1Stats.pointsAgainst += team2Score;
      team2Stats.pointsFor += team2Score;
      team2Stats.pointsAgainst += team1Score;
      
      // Track opponents for tie-breaking
      opponentHistory[game.team1Id!]!.add(game.team2Id!);
      opponentHistory[game.team2Id!]!.add(game.team1Id!);
      
      // Update wins/losses/points (Swiss uses match points)
      if (team1Score > team2Score) {
        team1Stats.wins++;
        team1Stats.points += 1; // 1 point for win in Swiss
        team2Stats.losses++;
      } else if (team2Score > team1Score) {
        team2Stats.wins++;
        team2Stats.points += 1; // 1 point for win in Swiss
        team1Stats.losses++;
      } else {
        team1Stats.draws++;
        team1Stats.points += 0.5; // 0.5 points for draw in Swiss
        team2Stats.draws++;
        team2Stats.points += 0.5;
      }
    }
    
    // Calculate tie-break values (Buchholz score - sum of opponent match points)
    final standings = teamStats.values.map((stats) {
      final pointsDifference = stats.pointsFor - stats.pointsAgainst;
      final winPercentage = stats.gamesPlayed > 0 
          ? stats.wins / stats.gamesPlayed 
          : 0.0;
      
      // Calculate Buchholz score (tie-breaker)
      double buchholzScore = 0.0;
      for (final opponentId in opponentHistory[stats.teamId] ?? []) {
        final opponentStats = teamStats[opponentId];
        if (opponentStats != null) {
          buchholzScore += opponentStats.points;
        }
      }
      
      return TeamStandingModel(
        teamId: stats.teamId,
        teamName: stats.teamName,
        position: 0, // Will be set after sorting
        wins: stats.wins,
        losses: stats.losses,
        draws: stats.draws,
        gamesPlayed: stats.gamesPlayed,
        pointsFor: stats.pointsFor,
        pointsAgainst: stats.pointsAgainst,
        pointsDifference: pointsDifference,
        winPercentage: winPercentage,
        points: (stats.points * 2).round(), // Convert to integer (multiply by 2 to handle 0.5 points)
        status: 'active',
        tieBreakValue: buchholzScore,
        isEliminated: false,
      );
    }).toList();
    
    // Sort by match points, then by tie-break value, then by point difference
    standings.sort((a, b) {
      // Primary: Match points (more is better)
      if (a.points != b.points) return b.points.compareTo(a.points);
      
      // Secondary: Tie-break value (more is better)
      if ((a.tieBreakValue ?? 0) != (b.tieBreakValue ?? 0)) {
        return (b.tieBreakValue ?? 0).compareTo(a.tieBreakValue ?? 0);
      }
      
      // Tertiary: Point difference (more is better)
      if (a.pointsDifference != b.pointsDifference) {
        return b.pointsDifference.compareTo(a.pointsDifference);
      }
      
      // Quaternary: Points for (more is better)
      return b.pointsFor.compareTo(a.pointsFor);
    });
    
    // Set positions
    for (int i = 0; i < standings.length; i++) {
      standings[i] = standings[i].copyWith(position: i + 1);
    }
    
    return TournamentStandingsModel(
      tournamentId: tournamentId,
      teamStandings: standings,
      format: 'swiss',
      lastUpdated: DateTime.now(),
      phase: phase ?? 'swiss',
      isFinal: isFinal,
    );
  }

  // Helper methods
  static String _getEliminationStatus(String? eliminatedIn) {
    if (eliminatedIn == null) return 'eliminated';
    
    final round = eliminatedIn.toLowerCase();
    if (round.contains('final')) return 'finalist';
    if (round.contains('semi')) return 'semifinalist';
    if (round.contains('quarter')) return 'quarterfinalist';
    return 'eliminated';
  }
  
  static int _getEliminationRoundValue(String? round) {
    if (round == null) return 0;
    
    final roundLower = round.toLowerCase();
    if (roundLower.contains('final')) return 100;
    if (roundLower.contains('semi')) return 90;
    if (roundLower.contains('quarter')) return 80;
    
    // Extract round number if present
    final RegExp regExp = RegExp(r'round (\d+)');
    final match = regExp.firstMatch(roundLower);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    
    return 0;
  }
}

// Helper class for accumulating team statistics
class _TeamStats {
  final String teamId;
  final String teamName;
  int wins = 0;
  int losses = 0;
  int draws = 0;
  int gamesPlayed = 0;
  int pointsFor = 0;
  int pointsAgainst = 0;
  double points = 0.0; // Tournament points (can be fractional for Swiss)
  
  _TeamStats({
    required this.teamId,
    required this.teamName,
  });
} 