// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_standings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentStandingsModel _$TournamentStandingsModelFromJson(
        Map<String, dynamic> json) =>
    TournamentStandingsModel(
      tournamentId: json['tournament_id'] as String,
      teamStandings: (json['team_standings'] as List<dynamic>)
          .map((e) => TeamStandingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      format: json['format'] as String,
      lastUpdated: json['last_updated'] == null
          ? null
          : DateTime.parse(json['last_updated'] as String),
      phase: json['phase'] as String?,
      isFinal: json['is_final'] as bool? ?? false,
    );

Map<String, dynamic> _$TournamentStandingsModelToJson(
        TournamentStandingsModel instance) =>
    <String, dynamic>{
      'tournament_id': instance.tournamentId,
      'team_standings': instance.teamStandings,
      'format': instance.format,
      'last_updated': instance.lastUpdated?.toIso8601String(),
      'phase': instance.phase,
      'is_final': instance.isFinal,
    };

TeamStandingModel _$TeamStandingModelFromJson(Map<String, dynamic> json) =>
    TeamStandingModel(
      teamId: json['team_id'] as String,
      teamName: json['team_name'] as String,
      position: (json['position'] as num).toInt(),
      wins: (json['wins'] as num).toInt(),
      losses: (json['losses'] as num).toInt(),
      draws: (json['draws'] as num).toInt(),
      gamesPlayed: (json['games_played'] as num?)?.toInt() ?? 0,
      pointsFor: (json['points_for'] as num?)?.toInt() ?? 0,
      pointsAgainst: (json['points_against'] as num?)?.toInt() ?? 0,
      pointsDifference: (json['points_difference'] as num?)?.toInt() ?? 0,
      winPercentage: (json['win_percentage'] as num?)?.toDouble() ?? 0.0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      seed: (json['seed'] as num?)?.toInt(),
      status: json['status'] as String?,
      eliminatedIn: json['eliminated_in'] as String?,
      notes: json['notes'] as String?,
      isEliminated: json['is_eliminated'] as bool? ?? false,
      advancesToNextRound: json['advances_to_next_round'] as bool? ?? false,
      tieBreakValue: (json['tie_break_value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TeamStandingModelToJson(TeamStandingModel instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'team_name': instance.teamName,
      'position': instance.position,
      'wins': instance.wins,
      'losses': instance.losses,
      'draws': instance.draws,
      'games_played': instance.gamesPlayed,
      'points_for': instance.pointsFor,
      'points_against': instance.pointsAgainst,
      'points_difference': instance.pointsDifference,
      'win_percentage': instance.winPercentage,
      'points': instance.points,
      'seed': instance.seed,
      'status': instance.status,
      'eliminated_in': instance.eliminatedIn,
      'notes': instance.notes,
      'is_eliminated': instance.isEliminated,
      'advances_to_next_round': instance.advancesToNextRound,
      'tie_break_value': instance.tieBreakValue,
    };
