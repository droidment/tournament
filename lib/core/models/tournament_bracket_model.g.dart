// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_bracket_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentBracketModel _$TournamentBracketModelFromJson(
        Map<String, dynamic> json) =>
    TournamentBracketModel(
      tournamentId: json['tournament_id'] as String,
      format: json['format'] as String,
      rounds: (json['rounds'] as List<dynamic>)
          .map((e) => BracketRoundModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isComplete: json['is_complete'] as bool? ?? false,
      winnerId: json['winner_id'] as String?,
      runnerId: json['runner_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TournamentBracketModelToJson(
        TournamentBracketModel instance) =>
    <String, dynamic>{
      'tournament_id': instance.tournamentId,
      'format': instance.format,
      'rounds': instance.rounds,
      'is_complete': instance.isComplete,
      'winner_id': instance.winnerId,
      'runner_id': instance.runnerId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

BracketRoundModel _$BracketRoundModelFromJson(Map<String, dynamic> json) =>
    BracketRoundModel(
      roundNumber: (json['round_number'] as num).toInt(),
      roundName: json['round_name'] as String,
      matches: (json['matches'] as List<dynamic>)
          .map((e) => BracketMatchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      bracketType: json['bracket_type'] as String? ?? 'winners',
      isComplete: json['is_complete'] as bool? ?? false,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
    );

Map<String, dynamic> _$BracketRoundModelToJson(BracketRoundModel instance) =>
    <String, dynamic>{
      'round_number': instance.roundNumber,
      'round_name': instance.roundName,
      'matches': instance.matches,
      'bracket_type': instance.bracketType,
      'is_complete': instance.isComplete,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
    };

BracketMatchModel _$BracketMatchModelFromJson(Map<String, dynamic> json) =>
    BracketMatchModel(
      matchNumber: (json['match_number'] as num).toInt(),
      position: (json['position'] as num).toInt(),
      gameId: json['game_id'] as String?,
      team1Id: json['team1_id'] as String?,
      team2Id: json['team2_id'] as String?,
      team1Seed: (json['team1_seed'] as num?)?.toInt(),
      team2Seed: (json['team2_seed'] as num?)?.toInt(),
      winnerId: json['winner_id'] as String?,
      team1Score: (json['team1_score'] as num?)?.toInt(),
      team2Score: (json['team2_score'] as num?)?.toInt(),
      isComplete: json['is_complete'] as bool? ?? false,
      isBye: json['is_bye'] as bool? ?? false,
      parentMatch1: (json['parent_match_1'] as num?)?.toInt(),
      parentMatch2: (json['parent_match_2'] as num?)?.toInt(),
      childMatch: (json['child_match'] as num?)?.toInt(),
      scheduledDateTime: json['scheduled_date_time'] == null
          ? null
          : DateTime.parse(json['scheduled_date_time'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$BracketMatchModelToJson(BracketMatchModel instance) =>
    <String, dynamic>{
      'match_number': instance.matchNumber,
      'position': instance.position,
      'game_id': instance.gameId,
      'team1_id': instance.team1Id,
      'team2_id': instance.team2Id,
      'team1_seed': instance.team1Seed,
      'team2_seed': instance.team2Seed,
      'winner_id': instance.winnerId,
      'team1_score': instance.team1Score,
      'team2_score': instance.team2Score,
      'is_complete': instance.isComplete,
      'is_bye': instance.isBye,
      'parent_match_1': instance.parentMatch1,
      'parent_match_2': instance.parentMatch2,
      'child_match': instance.childMatch,
      'scheduled_date_time': instance.scheduledDateTime?.toIso8601String(),
      'notes': instance.notes,
    };
