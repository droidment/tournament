import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tournament_bracket_model.g.dart';

@JsonSerializable()
class TournamentBracketModel extends Equatable {
  const TournamentBracketModel({
    required this.tournamentId,
    required this.format,
    required this.rounds,
    this.isComplete = false,
    this.winnerId,
    this.runnerId,
    this.createdAt,
    this.updatedAt,
  });

  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  
  final String format; // 'single_elimination', 'double_elimination'
  
  final List<BracketRoundModel> rounds;
  
  @JsonKey(name: 'is_complete')
  final bool isComplete;
  
  @JsonKey(name: 'winner_id')
  final String? winnerId; // Tournament winner
  
  @JsonKey(name: 'runner_id')
  final String? runnerId; // Tournament runner-up
  
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  factory TournamentBracketModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentBracketModelFromJson(json);

  Map<String, dynamic> toJson() => _$TournamentBracketModelToJson(this);

  @override
  List<Object?> get props => [
        tournamentId,
        format,
        rounds,
        isComplete,
        winnerId,
        runnerId,
        createdAt,
        updatedAt,
      ];

  TournamentBracketModel copyWith({
    String? tournamentId,
    String? format,
    List<BracketRoundModel>? rounds,
    bool? isComplete,
    String? winnerId,
    String? runnerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentBracketModel(
      tournamentId: tournamentId ?? this.tournamentId,
      format: format ?? this.format,
      rounds: rounds ?? this.rounds,
      isComplete: isComplete ?? this.isComplete,
      winnerId: winnerId ?? this.winnerId,
      runnerId: runnerId ?? this.runnerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isDoubleElimination => format == 'double_elimination';
  bool get isSingleElimination => format == 'single_elimination';
  
  int get totalRounds => rounds.length;
  
  BracketRoundModel? get currentRound {
    try {
      return rounds.reversed.firstWhere((round) => !round.isComplete);
    } catch (e) {
      return rounds.isNotEmpty ? rounds.last : null;
    }
  }
  
  List<BracketRoundModel> get winnersBracket {
    return rounds.where((round) => round.bracketType == 'winners').toList();
  }
  
  List<BracketRoundModel> get losersBracket {
    return rounds.where((round) => round.bracketType == 'losers').toList();
  }
}

@JsonSerializable()
class BracketRoundModel extends Equatable {
  const BracketRoundModel({
    required this.roundNumber,
    required this.roundName,
    required this.matches,
    this.bracketType = 'winners', // 'winners', 'losers', 'final'
    this.isComplete = false,
    this.startDate,
    this.endDate,
  });

  @JsonKey(name: 'round_number')
  final int roundNumber;
  
  @JsonKey(name: 'round_name')
  final String roundName; // 'Round 1', 'Quarterfinals', 'Semifinals', 'Final', etc.
  
  final List<BracketMatchModel> matches;
  
  @JsonKey(name: 'bracket_type')
  final String bracketType; // For double elimination
  
  @JsonKey(name: 'is_complete')
  final bool isComplete;
  
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime? endDate;

  factory BracketRoundModel.fromJson(Map<String, dynamic> json) =>
      _$BracketRoundModelFromJson(json);

  Map<String, dynamic> toJson() => _$BracketRoundModelToJson(this);

  @override
  List<Object?> get props => [
        roundNumber,
        roundName,
        matches,
        bracketType,
        isComplete,
        startDate,
        endDate,
      ];

  BracketRoundModel copyWith({
    int? roundNumber,
    String? roundName,
    List<BracketMatchModel>? matches,
    String? bracketType,
    bool? isComplete,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BracketRoundModel(
      roundNumber: roundNumber ?? this.roundNumber,
      roundName: roundName ?? this.roundName,
      matches: matches ?? this.matches,
      bracketType: bracketType ?? this.bracketType,
      isComplete: isComplete ?? this.isComplete,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  // Helper methods
  bool get allMatchesComplete => matches.every((match) => match.isComplete);
  bool get hasIncompleteMatches => matches.any((match) => !match.isComplete);
  
  int get completedMatchesCount => matches.where((match) => match.isComplete).length;
  int get totalMatchesCount => matches.length;
  
  double get completionPercentage => 
      totalMatchesCount > 0 ? completedMatchesCount / totalMatchesCount : 0.0;
}

@JsonSerializable()
class BracketMatchModel extends Equatable {
  const BracketMatchModel({
    required this.matchNumber,
    required this.position, // Position in the bracket (for visual layout)
    this.gameId, // Reference to actual game
    this.team1Id,
    this.team2Id,
    this.team1Seed,
    this.team2Seed,
    this.winnerId,
    this.team1Score,
    this.team2Score,
    this.isComplete = false,
    this.isBye = false,
    this.parentMatch1, // For tracking bracket progression
    this.parentMatch2,
    this.childMatch,
    this.scheduledDateTime,
    this.notes,
  });

  @JsonKey(name: 'match_number')
  final int matchNumber;
  
  final int position; // Position in bracket for UI layout
  
  @JsonKey(name: 'game_id')
  final String? gameId; // Reference to GameModel
  
  @JsonKey(name: 'team1_id')
  final String? team1Id;
  
  @JsonKey(name: 'team2_id')
  final String? team2Id;
  
  @JsonKey(name: 'team1_seed')
  final int? team1Seed;
  
  @JsonKey(name: 'team2_seed')
  final int? team2Seed;
  
  @JsonKey(name: 'winner_id')
  final String? winnerId;
  
  @JsonKey(name: 'team1_score')
  final int? team1Score;
  
  @JsonKey(name: 'team2_score')
  final int? team2Score;
  
  @JsonKey(name: 'is_complete')
  final bool isComplete;
  
  @JsonKey(name: 'is_bye')
  final bool isBye; // If one team gets a bye to next round
  
  @JsonKey(name: 'parent_match_1')
  final int? parentMatch1; // Match number that feeds into this match
  
  @JsonKey(name: 'parent_match_2')
  final int? parentMatch2; // Second match that feeds into this match
  
  @JsonKey(name: 'child_match')
  final int? childMatch; // Match that this match feeds into
  
  @JsonKey(name: 'scheduled_date_time')
  final DateTime? scheduledDateTime;
  
  final String? notes;

  factory BracketMatchModel.fromJson(Map<String, dynamic> json) =>
      _$BracketMatchModelFromJson(json);

  Map<String, dynamic> toJson() => _$BracketMatchModelToJson(this);

  @override
  List<Object?> get props => [
        matchNumber,
        position,
        gameId,
        team1Id,
        team2Id,
        team1Seed,
        team2Seed,
        winnerId,
        team1Score,
        team2Score,
        isComplete,
        isBye,
        parentMatch1,
        parentMatch2,
        childMatch,
        scheduledDateTime,
        notes,
      ];

  BracketMatchModel copyWith({
    int? matchNumber,
    int? position,
    String? gameId,
    String? team1Id,
    String? team2Id,
    int? team1Seed,
    int? team2Seed,
    String? winnerId,
    int? team1Score,
    int? team2Score,
    bool? isComplete,
    bool? isBye,
    int? parentMatch1,
    int? parentMatch2,
    int? childMatch,
    DateTime? scheduledDateTime,
    String? notes,
  }) {
    return BracketMatchModel(
      matchNumber: matchNumber ?? this.matchNumber,
      position: position ?? this.position,
      gameId: gameId ?? this.gameId,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      team1Seed: team1Seed ?? this.team1Seed,
      team2Seed: team2Seed ?? this.team2Seed,
      winnerId: winnerId ?? this.winnerId,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      isComplete: isComplete ?? this.isComplete,
      isBye: isBye ?? this.isBye,
      parentMatch1: parentMatch1 ?? this.parentMatch1,
      parentMatch2: parentMatch2 ?? this.parentMatch2,
      childMatch: childMatch ?? this.childMatch,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  bool get hasTeams => team1Id != null && team2Id != null;
  bool get hasResults => team1Score != null && team2Score != null;
  bool get canPlay => hasTeams && !isComplete && !isBye;
  bool get isReady => hasTeams || isBye;
  
  String? get loserTeamId {
    if (!isComplete || winnerId == null) return null;
    return winnerId == team1Id ? team2Id : team1Id;
  }
  
  String get displayName => 'Match $matchNumber';
  
  String? get scoreDisplay {
    if (!hasResults) return null;
    return '$team1Score - $team2Score';
  }
  
  String get matchupDisplay {
    if (isBye) return 'BYE';
    if (!hasTeams) return 'TBD vs TBD';
    
    final team1Display = team1Seed != null ? '($team1Seed)' : '';
    final team2Display = team2Seed != null ? '($team2Seed)' : '';
    
    return '$team1Display vs $team2Display';
  }
} 