import 'dart:math';
import 'package:teamapp3/core/models/tournament_bracket_model.dart';
import 'package:teamapp3/core/models/team_model.dart';
import 'package:teamapp3/core/models/game_model.dart';
import 'package:teamapp3/features/tournaments/data/repositories/game_repository.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_tier_model.dart';

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
    var currentDate = startDate;
    
    // First round with byes if needed
    final firstRoundMatches = _generateFirstRoundMatches(seededTeams, bracketSize);
    final firstRound = BracketRoundModel(
      roundNumber: 1,
      roundName: _getRoundName(1, totalRounds, false),
      matches: firstRoundMatches,
    );
    rounds.add(firstRound);

    // Generate subsequent rounds (empty initially)
    for (var round = 2; round <= totalRounds; round++) {
      final roundMatches = _generateEmptyRoundMatches(round, totalRounds);
      rounds.add(BracketRoundModel(
        roundNumber: round,
        roundName: _getRoundName(round, totalRounds, false),
        matches: roundMatches,
      ),);
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
    for (var round = 1; round <= winnersRounds; round++) {
      final matches = round == 1 
          ? _generateFirstRoundMatches(seededTeams, bracketSize)
          : _generateEmptyRoundMatches(round, winnersRounds, isWinnersBracket: true);
      
      rounds.add(BracketRoundModel(
        roundNumber: round,
        roundName: 'Winners ${_getRoundName(round, winnersRounds, false)}',
        matches: matches,
      ),);
    }

    // Generate losers bracket rounds
    for (var round = 1; round <= losersRounds; round++) {
      final matches = _generateEmptyRoundMatches(round, losersRounds, isLosersBracket: true);
      rounds.add(BracketRoundModel(
        roundNumber: winnersRounds + round,
        roundName: 'Losers Round $round',
        matches: matches,
        bracketType: 'losers',
      ),);
    }

    // Generate grand final
    rounds.add(BracketRoundModel(
      roundNumber: totalRounds,
      roundName: 'Grand Final',
      matches: const [
        BracketMatchModel(
          matchNumber: 1,
          position: 1,
          team1Score: null,
        ),
      ],
      bracketType: 'grand_final',
    ),);

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

  /// Generate tiered tournament brackets (Pro, Intermediate, Novice)
  Future<List<TournamentBracketModel>> generateTieredBrackets({
    required String tournamentId,
    required List<TournamentTierModel> tierAssignments,
    required Map<String, TeamModel> teamsMap,
    required List<String> resourceIds,
    required DateTime startDate,
    int gameDurationMinutes = 60,
    int timeBetweenGamesMinutes = 30,
  }) async {
    print('🏟️ Generating tiered tournament brackets');

    final brackets = <TournamentBracketModel>[];
    var currentStartDate = startDate;

    // Group teams by tier
    final tierTeams = <TournamentTier, List<TeamModel>>{};
    
    for (final tierAssignment in tierAssignments) {
      final team = teamsMap[tierAssignment.teamId];
      if (team != null) {
        tierTeams.putIfAbsent(tierAssignment.tier, () => []).add(team);
      }
    }

    // Generate bracket for each tier
    for (final tier in [TournamentTier.pro, TournamentTier.intermediate, TournamentTier.novice]) {
      final teams = tierTeams[tier] ?? [];
      
      if (teams.length < 2) {
        print('⚠️ Skipping ${tier.value} tier: insufficient teams (${teams.length})');
        continue;
      }

      // Sort teams by tier seed
      final sortedTeams = List<TeamModel>.from(teams);
      final tierSeeding = tierAssignments
          .where((t) => t.tier == tier)
          .toList()
        ..sort((a, b) => a.tierSeed.compareTo(b.tierSeed));
      
      sortedTeams.sort((a, b) {
        final aAssignment = tierSeeding.firstWhere((t) => t.teamId == a.id);
        final bAssignment = tierSeeding.firstWhere((t) => t.teamId == b.id);
        return aAssignment.tierSeed.compareTo(bAssignment.tierSeed);
      });

      // Generate single elimination bracket for this tier
      final tierBracket = await generateSingleEliminationBracket(
        tournamentId: tournamentId,
        teams: sortedTeams,
        resourceIds: resourceIds,
        startDate: currentStartDate,
        gameDurationMinutes: gameDurationMinutes,
        timeBetweenGamesMinutes: timeBetweenGamesMinutes,
        seeding: List.generate(sortedTeams.length, (index) => index + 1),
        randomizeSeeds: false,
      );

      // Update bracket format to indicate tier
      final updatedBracket = tierBracket.copyWith(
        format: '${tier.value}_elimination',
      );

      brackets.add(updatedBracket);

      // Stagger start times for different tiers (optional)
      currentStartDate = currentStartDate.add(Duration(minutes: 30));

      print('✅ Generated ${tier.value} tier bracket with ${sortedTeams.length} teams');
    }

    print('🏆 Tiered brackets generated: ${brackets.length} tiers');
    return brackets;
  }

  /// Generate a single tier bracket (used for each tier in tiered tournaments)
  Future<TournamentBracketModel> generateTierBracket({
    required String tournamentId,
    required TournamentTier tier,
    required List<TeamModel> teams,
    required List<String> resourceIds,
    required DateTime startDate,
    int gameDurationMinutes = 60,
    int timeBetweenGamesMinutes = 30,
  }) async {
    print('🏟️ Generating ${tier.value} tier bracket for ${teams.length} teams');

    if (teams.length < 2) {
      throw ArgumentError('Need at least 2 teams for tier bracket');
    }

    final bracket = await generateSingleEliminationBracket(
      tournamentId: tournamentId,
      teams: teams,
      resourceIds: resourceIds,
      startDate: startDate,
      gameDurationMinutes: gameDurationMinutes,
      timeBetweenGamesMinutes: timeBetweenGamesMinutes,
      randomizeSeeds: false,
    );

    return bracket.copyWith(
      format: '${tier.value}_elimination',
    );
  }

  String _getTierDisplayName(TournamentTier tier) {
    switch (tier) {
      case TournamentTier.pro:
        return 'Pro';
      case TournamentTier.intermediate:
        return 'Intermediate';
      case TournamentTier.novice:
        return 'Novice';
    }
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
    for (var roundIndex = 0; roundIndex < updatedRounds.length; roundIndex++) {
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
    var size = 1;
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
    for (var i = 0; i < seededTeams.length; i++) {
      teamsWithByes[_getSeedPosition(i, bracketSize)] = seededTeams[i];
    }

    // Create matches for first round
    for (var i = 0; i < bracketSize; i += 2) {
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
          winnerId: advancingTeam.id,
          isBye: true,
          isComplete: true,
        ),);
      } else {
        // Regular match
        matches.add(BracketMatchModel(
          matchNumber: matches.length + 1,
          position: matches.length + 1,
          team1Id: team1.id,
          team2Id: team2.id,
        ),);
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
    for (var i = 0; i < currentRoundMatches; i++) {
      matches.add(BracketMatchModel(
        matchNumber: i + 1,
        position: i + 1,
      ),);
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
           1, 30, 14, 17, 6, 25, 9, 22, 2, 29, 13, 18, 5, 26, 10, 21,],
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

    var currentDateTime = startDate;
    var resourceIndex = 0;

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
    print('🏃 Advancing winner ${completedMatch.winnerId} from round ${roundIndex + 1}');
    
    if (completedMatch.winnerId == null) {
      throw ArgumentError('Cannot advance winner: match has no winner');
    }

    // Handle single elimination advancement
    if (bracket.isSingleElimination) {
      await _advanceSingleEliminationWinner(
        bracket: bracket,
        completedMatch: completedMatch,
        roundIndex: roundIndex,
        matchIndex: matchIndex,
        resourceIds: resourceIds,
        gameDurationMinutes: gameDurationMinutes,
        timeBetweenGamesMinutes: timeBetweenGamesMinutes,
      );
    } else if (bracket.isDoubleElimination) {
      await _advanceDoubleEliminationWinner(
        bracket: bracket,
        completedMatch: completedMatch,
        roundIndex: roundIndex,
        matchIndex: matchIndex,
        resourceIds: resourceIds,
        gameDurationMinutes: gameDurationMinutes,
        timeBetweenGamesMinutes: timeBetweenGamesMinutes,
      );
    }
  }

  /// Advance winner in single elimination bracket
  Future<void> _advanceSingleEliminationWinner({
    required TournamentBracketModel bracket,
    required BracketMatchModel completedMatch,
    required int roundIndex,
    required int matchIndex,
    required List<String> resourceIds,
    required int gameDurationMinutes,
    required int timeBetweenGamesMinutes,
  }) async {
    // Check if there's a next round
    if (roundIndex + 1 >= bracket.rounds.length) {
      print('🏆 Tournament complete! Winner: ${completedMatch.winnerId}');
      return;
    }

    final currentRound = bracket.rounds[roundIndex];
    final nextRound = bracket.rounds[roundIndex + 1];
    
    // Calculate which match in the next round this winner advances to
    final nextMatchIndex = matchIndex ~/ 2;
    
    if (nextMatchIndex >= nextRound.matches.length) {
      print('❌ Error: Next match index out of bounds');
      return;
    }

    final nextMatch = nextRound.matches[nextMatchIndex];
    
    // Determine if winner goes to team1 or team2 slot
    final isTeam1Slot = (matchIndex % 2) == 0;
    
    // Update the next round match with the advancing team
    final updatedNextMatch = nextMatch.copyWith(
      team1Id: isTeam1Slot ? completedMatch.winnerId : nextMatch.team1Id,
      team2Id: !isTeam1Slot ? completedMatch.winnerId : nextMatch.team2Id,
    );

    // Update the bracket structure
    final updatedNextMatches = List<BracketMatchModel>.from(nextRound.matches);
    updatedNextMatches[nextMatchIndex] = updatedNextMatch;

    // Check if the next round is ready to start
    final updatedNextRound = nextRound.copyWith(matches: updatedNextMatches);
    
    // If this match now has both teams, create the game
    if (updatedNextMatch.hasTeams && updatedNextMatch.gameId == null) {
      await _createNextRoundGame(
        tournamentId: bracket.tournamentId,
        match: updatedNextMatch,
        round: updatedNextRound,
        resourceIds: resourceIds,
        gameDurationMinutes: gameDurationMinutes,
        timeBetweenGamesMinutes: timeBetweenGamesMinutes,
      );
    }

    print('✅ Advanced winner ${completedMatch.winnerId} to ${updatedNextRound.roundName}');
  }

  /// Advance winner in double elimination bracket (placeholder for future implementation)
  Future<void> _advanceDoubleEliminationWinner({
    required TournamentBracketModel bracket,
    required BracketMatchModel completedMatch,
    required int roundIndex,
    required int matchIndex,
    required List<String> resourceIds,
    required int gameDurationMinutes,
    required int timeBetweenGamesMinutes,
  }) async {
    // TODO: Implement double elimination advancement logic
    // This would handle:
    // - Winners bracket advancement
    // - Losers bracket advancement
    // - Grand final logic
    print('🔄 Double elimination advancement not yet implemented');
  }

  /// Create a game for the next round when both teams are ready
  Future<void> _createNextRoundGame({
    required String tournamentId,
    required BracketMatchModel match,
    required BracketRoundModel round,
    required List<String> resourceIds,
    required int gameDurationMinutes,
    required int timeBetweenGamesMinutes,
  }) async {
    if (!match.hasTeams || resourceIds.isEmpty) {
      return;
    }

    try {
      // Calculate start time based on previous round completion
      final startTime = DateTime.now().add(Duration(minutes: timeBetweenGamesMinutes));
      
      final game = await _gameRepository.createGame(
        tournamentId: tournamentId,
        round: round.roundNumber,
        roundName: round.roundName,
        team1Id: match.team1Id!,
        team2Id: match.team2Id!,
        resourceId: resourceIds[0], // Use first available resource
        scheduledDate: startTime,
        scheduledTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        estimatedDuration: gameDurationMinutes,
        notes: 'Bracket: ${round.roundName} - Match ${match.matchNumber}',
        isPublished: true,
      );

      print('🎮 Created next round game: ${game.id} for ${round.roundName}');
    } catch (e) {
      print('❌ Error creating next round game: $e');
    }
  }
} 