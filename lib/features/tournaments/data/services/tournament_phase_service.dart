import 'dart:math';
import 'package:teamapp3/core/models/game_model.dart';
import 'package:teamapp3/core/models/team_model.dart';
import 'package:teamapp3/core/models/tournament_resource_model.dart';
import 'package:teamapp3/core/models/tournament_standings_model.dart';
import 'package:teamapp3/core/models/tournament_bracket_model.dart';
import 'package:teamapp3/features/tournaments/data/repositories/game_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/team_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_resource_repository.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';
import 'package:teamapp3/features/tournaments/data/services/schedule_generator_service.dart';
import 'package:teamapp3/features/tournaments/data/services/tournament_standings_service.dart';
import 'package:teamapp3/features/tournaments/data/services/bracket_generator_service.dart';

class TournamentPhaseService {
  final GameRepository _gameRepository = GameRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final TournamentResourceRepository _resourceRepository = TournamentResourceRepository();
  final BracketGeneratorService _bracketGenerator = BracketGeneratorService();

  /// Check if round robin phase is complete and ready for elimination
  Future<RoundRobinCompletionStatus> checkRoundRobinCompletion({
    required String tournamentId,
  }) async {
    try {
      print('🔍 Checking round robin completion for tournament: $tournamentId');
      
      // Load tournament data
      final games = await _gameRepository.getTournamentGames(tournamentId);
      final teams = await _teamRepository.getTournamentTeams(tournamentId);
      
      // Filter round robin games (assuming they have roundName = 'Round Robin')
      final roundRobinGames = games.where((game) => 
        game.roundName?.toLowerCase().contains('round robin') == true ||
        game.roundName?.toLowerCase().contains('robin') == true,
      ).toList();
      
      if (roundRobinGames.isEmpty) {
        print('❌ No round robin games found');
        return RoundRobinCompletionStatus(
          isComplete: false,
          completedGames: 0,
          totalGames: 0,
          completionPercentage: 0,
          message: 'No round robin games found',
        );
      }
      
      // Calculate expected vs actual games
      final expectedGames = ScheduleGeneratorService.calculateRoundRobinGames(teams.length);
      final completedGames = roundRobinGames.where((game) => 
        game.status == GameStatus.completed,
      ).toList();
      
      final completionPercentage = roundRobinGames.isNotEmpty 
          ? (completedGames.length / roundRobinGames.length) * 100
          : 0.0;
      
      final isComplete = completedGames.length == roundRobinGames.length && 
                        roundRobinGames.length >= expectedGames;
      
      print('📊 Round Robin Status:');
      print('   Teams: ${teams.length}');
      print('   Expected games: $expectedGames');
      print('   Scheduled games: ${roundRobinGames.length}');
      print('   Completed games: ${completedGames.length}');
      print('   Completion: ${completionPercentage.toStringAsFixed(1)}%');
      print('   Is Complete: $isComplete');
      
      String message;
      if (isComplete) {
        message = 'Round robin complete! Ready for elimination bracket.';
      } else if (completedGames.isEmpty) {
        message = 'Round robin has not started yet.';
      } else {
        final remaining = roundRobinGames.length - completedGames.length;
        message = '$remaining games remaining in round robin.';
      }
      
      return RoundRobinCompletionStatus(
        isComplete: isComplete,
        completedGames: completedGames.length,
        totalGames: roundRobinGames.length,
        expectedGames: expectedGames,
        completionPercentage: completionPercentage,
        message: message,
        roundRobinGames: roundRobinGames,
        standings: isComplete ? TournamentStandingsService.calculateStandings(
          tournamentId: tournamentId,
          format: TournamentFormat.roundRobin,
          games: completedGames,
          teams: teams,
          phase: 'round_robin',
          isFinal: true,
        ) : null,
      );
      
    } catch (e) {
      print('❌ Error checking round robin completion: $e');
      return RoundRobinCompletionStatus(
        isComplete: false,
        completedGames: 0,
        totalGames: 0,
        completionPercentage: 0,
        message: 'Error checking completion: $e',
      );
    }
  }

  /// Automatically transition from round robin to elimination bracket
  Future<TournamentBracketModel?> transitionToEliminationBracket({
    required String tournamentId,
    required String bracketFormat, // 'single_elimination' or 'double_elimination'
    required DateTime bracketStartDate,
    int gameDurationMinutes = 60,
    int timeBetweenGamesMinutes = 30,
    int? topTeamsCount, // If null, includes all teams
  }) async {
    try {
      print('🚀 Starting transition to elimination bracket for tournament: $tournamentId');
      
      // 1. Verify round robin is complete
      final completionStatus = await checkRoundRobinCompletion(tournamentId: tournamentId);
      if (!completionStatus.isComplete) {
        throw Exception('Round robin is not complete yet. ${completionStatus.message}');
      }
      
      if (completionStatus.standings == null) {
        throw Exception('Could not calculate final standings from round robin');
      }
      
             // 2. Get seeded teams based on standings
       final standings = completionStatus.standings!;
       final allTeams = await _teamRepository.getTournamentTeams(tournamentId);
      final seededTeams = _getSeededTeamsFromStandings(standings, allTeams, topTeamsCount);
      
      if (seededTeams.length < 2) {
        throw Exception('Need at least 2 teams for elimination bracket');
      }
      
      print('🏆 Seeded teams for bracket:');
      for (var i = 0; i < seededTeams.length; i++) {
        final team = seededTeams[i];
        final standing = standings.teamStandings.firstWhere((s) => s.teamId == team.id);
        print('   ${i + 1}. ${team.name} (${standing.wins}-${standing.losses}, ${standing.points} pts)');
      }
      
             // 3. Get tournament resources
       final resources = await _resourceRepository.getTournamentResources(tournamentId);
      final resourceIds = resources.map((r) => r.id).toList();
      
      if (resourceIds.isEmpty) {
        throw Exception('No resources available for bracket games');
      }
      
      // 4. Generate elimination bracket
      TournamentBracketModel bracket;
      if (bracketFormat == 'double_elimination') {
        bracket = await _bracketGenerator.generateDoubleEliminationBracket(
          tournamentId: tournamentId,
          teams: seededTeams,
          resourceIds: resourceIds,
          startDate: bracketStartDate,
          gameDurationMinutes: gameDurationMinutes,
          timeBetweenGamesMinutes: timeBetweenGamesMinutes,
          seeding: List.generate(seededTeams.length, (index) => index), // Use standing order
        );
      } else {
        bracket = await _bracketGenerator.generateSingleEliminationBracket(
          tournamentId: tournamentId,
          teams: seededTeams,
          resourceIds: resourceIds,
          startDate: bracketStartDate,
          gameDurationMinutes: gameDurationMinutes,
          timeBetweenGamesMinutes: timeBetweenGamesMinutes,
          seeding: List.generate(seededTeams.length, (index) => index), // Use standing order
        );
      }
      
      print('✅ Successfully created $bracketFormat bracket with ${bracket.rounds.length} rounds');
      print('🎮 First round has ${bracket.rounds.first.matches.length} matches');
      
      return bracket;
      
    } catch (e) {
      print('❌ Error transitioning to elimination bracket: $e');
      rethrow;
    }
  }

  /// Get teams seeded based on round robin standings
  List<TeamModel> _getSeededTeamsFromStandings(
    TournamentStandingsModel standings,
    List<TeamModel> allTeams,
    int? topTeamsCount,
  ) {
    // Sort standings to ensure proper seeding (best team = seed 1)
    final sortedStandings = List<TeamStandingModel>.from(standings.teamStandings)
      ..sort((a, b) => a.position.compareTo(b.position));
    
    // Determine how many teams to include
    final teamsToInclude = topTeamsCount ?? sortedStandings.length;
    final selectedStandings = sortedStandings.take(teamsToInclude).toList();
    
    // Convert standings to teams in seeded order
    final seededTeams = <TeamModel>[];
    for (final standing in selectedStandings) {
      final team = allTeams.firstWhere((t) => t.id == standing.teamId);
      seededTeams.add(team);
    }
    
    return seededTeams;
  }

  /// Check if elimination bracket is ready to start
  Future<bool> canStartEliminationBracket({
    required String tournamentId,
  }) async {
    final status = await checkRoundRobinCompletion(tournamentId: tournamentId);
    return status.isComplete;
  }

  /// Get tournament phase status
  Future<TournamentPhaseStatus> getTournamentPhaseStatus({
    required String tournamentId,
  }) async {
         try {
       final games = await _gameRepository.getTournamentGames(tournamentId);
      
      // Check for round robin games
      final roundRobinGames = games.where((game) => 
        game.roundName?.toLowerCase().contains('round robin') == true ||
        game.roundName?.toLowerCase().contains('robin') == true,
      ).toList();
      
      // Check for elimination games (games with round numbers and non-round-robin names)
      final eliminationGames = games.where((game) => 
        game.round != null && 
        game.round! > 0 &&
        !(game.roundName?.toLowerCase().contains('round robin') == true ||
          game.roundName?.toLowerCase().contains('robin') == true),
      ).toList();
      
      if (eliminationGames.isNotEmpty) {
        // Tournament has elimination games
        final completedElimination = eliminationGames.where((g) => g.status == GameStatus.completed).length;
        final totalElimination = eliminationGames.length;
        
        return TournamentPhaseStatus(
          currentPhase: 'elimination',
          roundRobinComplete: roundRobinGames.isNotEmpty,
          eliminationActive: true,
          eliminationComplete: completedElimination == totalElimination && totalElimination > 0,
          nextPhase: completedElimination == totalElimination ? null : 'elimination_in_progress',
        );
      } else if (roundRobinGames.isNotEmpty) {
        // Tournament has round robin games but no elimination yet
        final completionStatus = await checkRoundRobinCompletion(tournamentId: tournamentId);
        
        return TournamentPhaseStatus(
          currentPhase: 'round_robin',
          roundRobinComplete: completionStatus.isComplete,
          eliminationActive: false,
          eliminationComplete: false,
          nextPhase: completionStatus.isComplete ? 'elimination_ready' : 'round_robin_in_progress',
        );
      } else {
        // No games yet
        return TournamentPhaseStatus(
          currentPhase: 'setup',
          roundRobinComplete: false,
          eliminationActive: false,
          eliminationComplete: false,
          nextPhase: 'round_robin_ready',
        );
      }
      
    } catch (e) {
      print('❌ Error getting tournament phase status: $e');
      return TournamentPhaseStatus(
        currentPhase: 'unknown',
        roundRobinComplete: false,
        eliminationActive: false,
        eliminationComplete: false,
      );
    }
  }
}

/// Status of round robin completion
class RoundRobinCompletionStatus {

  RoundRobinCompletionStatus({
    required this.isComplete,
    required this.completedGames,
    required this.totalGames,
    this.expectedGames,
    required this.completionPercentage,
    required this.message,
    this.roundRobinGames,
    this.standings,
  });
  final bool isComplete;
  final int completedGames;
  final int totalGames;
  final int? expectedGames;
  final double completionPercentage;
  final String message;
  final List<GameModel>? roundRobinGames;
  final TournamentStandingsModel? standings;
}

/// Overall tournament phase status
class TournamentPhaseStatus { // What phase can be started next

  TournamentPhaseStatus({
    required this.currentPhase,
    required this.roundRobinComplete,
    required this.eliminationActive,
    required this.eliminationComplete,
    this.nextPhase,
  });
  final String currentPhase; // 'setup', 'round_robin', 'elimination'
  final bool roundRobinComplete;
  final bool eliminationActive;
  final bool eliminationComplete;
  final String? nextPhase;
}

 