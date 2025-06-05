import 'dart:math';
import '../../../../core/models/tournament_bracket_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/game_model.dart';
import '../repositories/game_repository.dart';

class BracketGeneratorService {
  final GameRepository _gameRepository = GameRepository();

  /// Generate a single elimination bracket
  Future<TournamentBracketModel> generateSingleEliminationBracket({
    required String tournamentId,
    required List<TeamModel> teams,
    required List<String> resourceIds,
    required DateTime startDate,
    int gameDurationMinutes = 60,
    int timeBetweenGamesMinutes = 30,
    List<int>? seeding, // Custom seeding order
    bool randomizeSeeds = false,
  }) async {
    print('🌳 Generating single elimination bracket for ${teams.length} teams');

    if (teams.length < 2) {
      throw ArgumentError('Need at least 2 teams for elimination bracket');
    }

    // Prepare seeded teams
    final seededTeams = _seedTeams(teams, seeding, randomizeSeeds);
    
    // Calculate bracket structure
    final bracketSize = _calculateBracketSize(seededTeams.length);
    final totalRounds = _calculateRounds(bracketSize);
    
    // Generate all rounds
    final rounds = <BracketRoundModel>[];
    DateTime currentDate = startDate;
    
    // First round with byes if needed
    final firstRoundMatches = _generateFirstRoundMatches(seededTeams, bracketSize);
    final firstRound = BracketRoundModel(
      roundNumber: 1,
      roundName: _getRoundName(1, totalRounds, false),
      matches: firstRoundMatches,
      isComplete: false,
    );
    rounds.add(firstRound);

    // Generate subsequent rounds (empty initially)
    for (int round = 2; round <= totalRounds; round++) {
      final roundMatches = _generateEmptyRoundMatches(round, totalRounds);
      rounds.add(BracketRoundModel(
        roundNumber: round,
        roundName: _getRoundName(round, totalRounds, false),
        matches: roundMatches,
        isComplete: false,
      ));
    }

    // Create and save games for the first round
    await _createBracketGames(
      tournamentId: tournamentId,
      rounds: [firstRound],
      resourceIds: resourceIds,
      startDate: currentDate,
      gameDurationMinutes: gameDurationMinutes,
      timeBetweenGamesMinutes: timeBetweenGamesMinutes,
    );

    print('✅ Single elimination bracket generated with $totalRounds rounds');

    return TournamentBracketModel(
      tournamentId: tournamentId,
      format: 'single_elimination',
      rounds: rounds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a double elimination bracket
  Future<TournamentBracketModel> generateDoubleEliminationBracket({
    required String tournamentId,
    required List<TeamModel> teams,
    required List<String> resourceIds,
    required DateTime startDate,
    int gameDurationMinutes = 60,
    int timeBetweenGamesMinutes = 30,
    List<int>? seeding,
    bool randomizeSeeds = false,
  }) async {
    print('🌳 Generating double elimination bracket for ${teams.length} teams');

    if (teams.length < 3) {
      throw ArgumentError('Need at least 3 teams for double elimination');
    }

    final seededTeams = _seedTeams(teams, seeding, randomizeSeeds);
    final bracketSize = _calculateBracketSize(seededTeams.length);
    
    // Double elimination has winners and losers brackets
    final winnersRounds = _calculateRounds(bracketSize);
    final losersRounds = _calculateLosersRounds(bracketSize);
    final totalRounds = winnersRounds + losersRounds + 1; // +1 for grand final

    final rounds = <BracketRoundModel>[];
    
    // Generate winners bracket rounds
    for (int round = 1; round <= winnersRounds; round++) {
      final matches = round == 1 
          ? _generateFirstRoundMatches(seededTeams, bracketSize)
          : _generateEmptyRoundMatches(round, winnersRounds, isWinnersBracket: true);
      
      rounds.add(BracketRoundModel(
        roundNumber: round,
        roundName: 'Winners ${_getRoundName(round, winnersRounds, false)}',
        matches: matches,
        isComplete: false,
        bracketType: 'winners',
      ));
    }

    // Generate losers bracket rounds
    for (int round = 1; round <= losersRounds; round++) {
      final matches = _generateEmptyRoundMatches(round, losersRounds, isLosersBracket: true);
      rounds.add(BracketRoundModel(
        roundNumber: winnersRounds + round,
        roundName: 'Losers Round $round',
        matches: matches,
        isComplete: false,
        bracketType: 'losers',
      ));
    }

    // Generate grand final
    rounds.add(BracketRoundModel(
      roundNumber: totalRounds,
      roundName: 'Grand Final',
      matches: [
        BracketMatchModel(
          matchNumber: 1,
          position: 1,
          team1Id: null, // TBD
          team2Id: null, // TBD
          winnerId: null,
          team1Score: null,
          team2Score: null,
          isComplete: false,
          scheduledDateTime: null,
        ),
      ],
      isComplete: false,
      bracketType: 'grand_final',
    ));

    // Create games for first round
    await _createBracketGames(
      tournamentId: tournamentId,
      rounds: rounds.where((r) => r.roundNumber == 1).toList(),
      resourceIds: resourceIds,
      startDate: startDate,
      gameDurationMinutes: gameDurationMinutes,
      timeBetweenGamesMinutes: timeBetweenGamesMinutes,
    );

    print('✅ Double elimination bracket generated');

    return TournamentBracketModel(
      tournamentId: tournamentId,
      format: 'double_elimination',
      rounds: rounds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Advance bracket after a game completion
  Future<TournamentBracketModel> advanceBracket({
    required TournamentBracketModel bracket,
    required GameModel completedGame,
    required List<String> resourceIds,
    int gameDurationMinutes = 60,
    int timeBetweenGamesMinutes = 30,
  }) async {
    print('⚡ Advancing bracket after game completion: ${completedGame.id}');

    if (completedGame.status != GameStatus.completed || completedGame.winnerId == null) {
      throw ArgumentError('Game must be completed with a winner to advance bracket');
    }

    final updatedRounds = List<BracketRoundModel>.from(bracket.rounds);
    
    // Find the completed match and advance winner
    for (int roundIndex = 0; roundIndex < updatedRounds.length; roundIndex++) {
      final round = updatedRounds[roundIndex];
      final matchIndex = round.matches.indexWhere((m) => m.gameId == completedGame.id);
      
      if (matchIndex >= 0) {
        // Update the completed match
        final updatedMatches = List<BracketMatchModel>.from(round.matches);
        updatedMatches[matchIndex] = updatedMatches[matchIndex].copyWith(
          winnerId: completedGame.winnerId,
          team1Score: completedGame.team1Score,
          team2Score: completedGame.team2Score,
          isComplete: true,
        );

        // Update the round
        updatedRounds[roundIndex] = round.copyWith(
          matches: updatedMatches,
          isComplete: updatedMatches.every((m) => m.isComplete),
        );

        // Advance winner to next round
        await _advanceWinner(
          bracket: bracket.copyWith(rounds: updatedRounds),
          completedMatch: updatedMatches[matchIndex],
          roundIndex: roundIndex,
          matchIndex: matchIndex,
          resourceIds: resourceIds,
          gameDurationMinutes: gameDurationMinutes,
          timeBetweenGamesMinutes: timeBetweenGamesMinutes,
        );

        break;
      }
    }

    return bracket.copyWith(
      rounds: updatedRounds,
      updatedAt: DateTime.now(),
    );
  }

  /// Seed teams for bracket
  List<TeamModel> _seedTeams(List<TeamModel> teams, List<int>? customSeeding, bool randomize) {
    if (customSeeding != null && customSeeding.length == teams.length) {
      // Use custom seeding
      final seededTeams = <TeamModel>[];
      for (final seed in customSeeding) {
        if (seed >= 0 && seed < teams.length) {
          seededTeams.add(teams[seed]);
        }
      }
      return seededTeams;
    }

    if (randomize) {
      // Randomize seeding
      final shuffledTeams = List<TeamModel>.from(teams);
      shuffledTeams.shuffle(Random());
      return shuffledTeams;
    }

    // Default: teams in input order
    return List<TeamModel>.from(teams);
  }

  /// Calculate bracket size (next power of 2)
  int _calculateBracketSize(int teamCount) {
    int size = 1;
    while (size < teamCount) {
      size *= 2;
    }
    return size;
  }

  /// Calculate number of rounds
  int _calculateRounds(int bracketSize) {
    return (log(bracketSize) / log(2)).ceil();
  }

  /// Calculate losers bracket rounds for double elimination
  int _calculateLosersRounds(int bracketSize) {
    final winnersRounds = _calculateRounds(bracketSize);
    return (winnersRounds * 2) - 2;
  }

  /// Generate first round matches with byes
  List<BracketMatchModel> _generateFirstRoundMatches(List<TeamModel> seededTeams, int bracketSize) {
    final matches = <BracketMatchModel>[];
    final teamsWithByes = List<TeamModel?>.filled(bracketSize, null);
    
    // Place teams using standard tournament seeding
    for (int i = 0; i < seededTeams.length; i++) {
      teamsWithByes[_getSeedPosition(i, bracketSize)] = seededTeams[i];
    }

    // Create matches for first round
    for (int i = 0; i < bracketSize; i += 2) {
      final team1 = teamsWithByes[i];
      final team2 = teamsWithByes[i + 1];

      // Handle byes
      if (team1 == null && team2 == null) continue;
      if (team1 == null || team2 == null) {
        // One team gets a bye - advance automatically
        final advancingTeam = team1 ?? team2;
        matches.add(BracketMatchModel(
          matchNumber: matches.length + 1,
          position: matches.length + 1,
          team1Id: advancingTeam!.id,
          team2Id: null,
          winnerId: advancingTeam.id,
          team1Score: null,
          team2Score: null,
          isBye: true,
          isComplete: true,
          scheduledDateTime: null,
        ));
      } else {
        // Regular match
        matches.add(BracketMatchModel(
          matchNumber: matches.length + 1,
          position: matches.length + 1,
          team1Id: team1.id,
          team2Id: team2.id,
          winnerId: null,
          team1Score: null,
          team2Score: null,
          isComplete: false,
          isBye: false,
          scheduledDateTime: null,
        ));
      }
    }

    return matches;
  }

  /// Generate empty matches for subsequent rounds
  List<BracketMatchModel> _generateEmptyRoundMatches(
    int round, 
    int totalRounds, {
    bool isWinnersBracket = false,
    bool isLosersBracket = false,
  }) {
    final previousRoundMatches = pow(2, totalRounds - round + 1).toInt();
    final currentRoundMatches = previousRoundMatches ~/ 2;
    
    if (currentRoundMatches < 1) return [];

    final matches = <BracketMatchModel>[];
    for (int i = 0; i < currentRoundMatches; i++) {
      matches.add(BracketMatchModel(
        matchNumber: i + 1,
        position: i + 1,
        team1Id: null,
        team2Id: null,
        winnerId: null,
        team1Score: null,
        team2Score: null,
        isComplete: false,
        isBye: false,
        scheduledDateTime: null,
      ));
    }
    
    return matches;
  }

  /// Get standard tournament seeding position
  int _getSeedPosition(int seedIndex, int bracketSize) {
    // Standard tournament seeding pattern
    final seedPositions = <int, List<int>>{
      2: [0, 1],
      4: [0, 3, 1, 2],
      8: [0, 7, 3, 4, 1, 6, 2, 5],
      16: [0, 15, 7, 8, 3, 12, 4, 11, 1, 14, 6, 9, 2, 13, 5, 10],
      32: [0, 31, 15, 16, 7, 24, 8, 23, 3, 28, 12, 19, 4, 27, 11, 20, 
           1, 30, 14, 17, 6, 25, 9, 22, 2, 29, 13, 18, 5, 26, 10, 21],
    };

    final positions = seedPositions[bracketSize];
    if (positions != null && seedIndex < positions.length) {
      return positions[seedIndex];
    }

    // Fallback for unsupported bracket sizes
    return seedIndex % bracketSize;
  }

  /// Get round name based on position
  String _getRoundName(int round, int totalRounds, bool isDoubleElimination) {
    final remainingRounds = totalRounds - round + 1;
    
    if (remainingRounds == 1) return 'Final';
    if (remainingRounds == 2) return 'Semifinal';
    if (remainingRounds == 3) return 'Quarterfinal';
    if (remainingRounds == 4) return 'Round of 16';
    if (remainingRounds == 5) return 'Round of 32';
    
    return 'Round $round';
  }

  /// Create actual games for bracket matches
  Future<void> _createBracketGames({
    required String tournamentId,
    required List<BracketRoundModel> rounds,
    required List<String> resourceIds,
    required DateTime startDate,
    required int gameDurationMinutes,
    required int timeBetweenGamesMinutes,
  }) async {
    if (resourceIds.isEmpty) {
      throw ArgumentError('Need at least one resource to schedule bracket games');
    }

    DateTime currentDateTime = startDate;
    int resourceIndex = 0;

    for (final round in rounds) {
      for (final match in round.matches) {
        if (match.isBye || match.team1Id == null || match.team2Id == null) {
          continue; // Skip byes and TBD matches
        }

        try {
          final game = await _gameRepository.createGame(
            tournamentId: tournamentId,
            round: round.roundNumber,
            roundName: round.roundName,
            team1Id: match.team1Id,
            team2Id: match.team2Id,
            resourceId: resourceIds[resourceIndex % resourceIds.length],
            scheduledDate: currentDateTime,
            scheduledTime: '${currentDateTime.hour.toString().padLeft(2, '0')}:${currentDateTime.minute.toString().padLeft(2, '0')}',
            estimatedDuration: gameDurationMinutes,
            notes: 'Bracket: Match ${match.matchNumber}',
            isPublished: true,
          );

          // Link game to bracket match
          // This would require updating the match model to store gameId
          print('🎮 Created bracket game: ${game.id} for match ${match.matchNumber}');

          // Move to next time slot
          currentDateTime = currentDateTime.add(Duration(minutes: gameDurationMinutes + timeBetweenGamesMinutes));
          resourceIndex++;
        } catch (e) {
          print('❌ Error creating game for match ${match.matchNumber}: $e');
          throw Exception('Failed to create bracket game: $e');
        }
      }
    }
  }

  /// Advance winner to next round
  Future<void> _advanceWinner({
    required TournamentBracketModel bracket,
    required BracketMatchModel completedMatch,
    required int roundIndex,
    required int matchIndex,
    required List<String> resourceIds,
    required int gameDurationMinutes,
    required int timeBetweenGamesMinutes,
  }) async {
    // Implementation for advancing winners would go here
    // This involves complex logic for different bracket types
    print('🏃 Advancing winner ${completedMatch.winnerId} from round ${roundIndex + 1}');
    
    // For now, this is a placeholder for the complex advancement logic
    // Real implementation would handle:
    // - Single elimination advancement
    // - Double elimination (winners/losers bracket management)
    // - Creating next round games when round is complete
    // - Determining final standings
  }
} 