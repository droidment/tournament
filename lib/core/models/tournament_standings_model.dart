import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tournament_standings_model.g.dart';

@JsonSerializable()
class TournamentStandingsModel extends Equatable { // Whether these standings are final/complete

  factory TournamentStandingsModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentStandingsModelFromJson(json);
  const TournamentStandingsModel({
    required this.tournamentId,
    required this.teamStandings,
    required this.format,
    this.lastUpdated,
    this.phase,
    this.isFinal = false,
  });

  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  
  @JsonKey(name: 'team_standings')
  final List<TeamStandingModel> teamStandings;
  
  final String format; // round_robin, single_elimination, double_elimination, swiss
  
  @JsonKey(name: 'last_updated')
  final DateTime? lastUpdated;
  
  final String? phase; // group_stage, playoffs, finals, etc.
  
  @JsonKey(name: 'is_final')
  final bool isFinal;

  Map<String, dynamic> toJson() => _$TournamentStandingsModelToJson(this);

  @override
  List<Object?> get props => [
        tournamentId,
        teamStandings,
        format,
        lastUpdated,
        phase,
        isFinal,
      ];

  TournamentStandingsModel copyWith({
    String? tournamentId,
    List<TeamStandingModel>? teamStandings,
    String? format,
    DateTime? lastUpdated,
    String? phase,
    bool? isFinal,
  }) {
    return TournamentStandingsModel(
      tournamentId: tournamentId ?? this.tournamentId,
      teamStandings: teamStandings ?? this.teamStandings,
      format: format ?? this.format,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      phase: phase ?? this.phase,
      isFinal: isFinal ?? this.isFinal,
    );
  }
}

@JsonSerializable()
class TeamStandingModel extends Equatable { // For Swiss system tie-breaking

  factory TeamStandingModel.fromJson(Map<String, dynamic> json) =>
      _$TeamStandingModelFromJson(json);
  const TeamStandingModel({
    required this.teamId,
    required this.teamName,
    required this.position,
    required this.wins,
    required this.losses,
    required this.draws,
    this.gamesPlayed = 0,
    this.pointsFor = 0,
    this.pointsAgainst = 0,
    this.pointsDifference = 0,
    this.winPercentage = 0.0,
    this.points = 0, // Tournament points (3 for win, 1 for draw, 0 for loss in most systems)
    this.seed,
    this.status,
    this.eliminatedIn,
    this.notes,
    this.isEliminated = false,
    this.advancesToNextRound = false,
    this.tieBreakValue,
  });

  @JsonKey(name: 'team_id')
  final String teamId;
  
  @JsonKey(name: 'team_name')
  final String teamName;
  
  final int position; // Current standing position (1st, 2nd, etc.)
  
  final int wins;
  final int losses;
  final int draws;
  
  @JsonKey(name: 'games_played')
  final int gamesPlayed;
  
  @JsonKey(name: 'points_for')
  final int pointsFor; // Total points scored
  
  @JsonKey(name: 'points_against')
  final int pointsAgainst; // Total points conceded
  
  @JsonKey(name: 'points_difference')
  final int pointsDifference; // Point differential
  
  @JsonKey(name: 'win_percentage')
  final double winPercentage;
  
  final int points; // Tournament points
  
  final int? seed; // Original seeding
  
  final String? status; // active, eliminated, champion, finalist, etc.
  
  @JsonKey(name: 'eliminated_in')
  final String? eliminatedIn; // Which round they were eliminated
  
  final String? notes;
  
  @JsonKey(name: 'is_eliminated')
  final bool isEliminated;
  
  @JsonKey(name: 'advances_to_next_round')
  final bool advancesToNextRound;
  
  @JsonKey(name: 'tie_break_value')
  final double? tieBreakValue;

  Map<String, dynamic> toJson() => _$TeamStandingModelToJson(this);

  @override
  List<Object?> get props => [
        teamId,
        teamName,
        position,
        wins,
        losses,
        draws,
        gamesPlayed,
        pointsFor,
        pointsAgainst,
        pointsDifference,
        winPercentage,
        points,
        seed,
        status,
        eliminatedIn,
        notes,
        isEliminated,
        advancesToNextRound,
        tieBreakValue,
      ];

  TeamStandingModel copyWith({
    String? teamId,
    String? teamName,
    int? position,
    int? wins,
    int? losses,
    int? draws,
    int? gamesPlayed,
    int? pointsFor,
    int? pointsAgainst,
    int? pointsDifference,
    double? winPercentage,
    int? points,
    int? seed,
    String? status,
    String? eliminatedIn,
    String? notes,
    bool? isEliminated,
    bool? advancesToNextRound,
    double? tieBreakValue,
  }) {
    return TeamStandingModel(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      position: position ?? this.position,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      pointsFor: pointsFor ?? this.pointsFor,
      pointsAgainst: pointsAgainst ?? this.pointsAgainst,
      pointsDifference: pointsDifference ?? this.pointsDifference,
      winPercentage: winPercentage ?? this.winPercentage,
      points: points ?? this.points,
      seed: seed ?? this.seed,
      status: status ?? this.status,
      eliminatedIn: eliminatedIn ?? this.eliminatedIn,
      notes: notes ?? this.notes,
      isEliminated: isEliminated ?? this.isEliminated,
      advancesToNextRound: advancesToNextRound ?? this.advancesToNextRound,
      tieBreakValue: tieBreakValue ?? this.tieBreakValue,
    );
  }

  // Helper methods
  double get efficiency => gamesPlayed > 0 ? points / gamesPlayed : 0.0;
  
  String get record => '$wins-$losses${draws > 0 ? '-$draws' : ''}';
  
  String get statusDisplayName {
    switch (status) {
      case 'champion':
        return 'Champion 🏆';
      case 'finalist':
        return 'Finalist 🥈';
      case 'semifinalist':
        return 'Semifinalist 🥉';
      case 'quarterfinalist':
        return 'Quarterfinalist';
      case 'eliminated':
        return 'Eliminated';
      case 'active':
      default:
        return 'Active';
    }
  }
} 