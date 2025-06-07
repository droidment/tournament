// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_tier_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentTierModel _$TournamentTierModelFromJson(Map<String, dynamic> json) =>
    TournamentTierModel(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      teamId: json['team_id'] as String,
      tierValue: json['tier'] as String,
      groupPosition: (json['group_position'] as num).toInt(),
      groupPoints: (json['group_points'] as num).toInt(),
      pointDifferential: (json['point_differential'] as num).toInt(),
      tierSeed: (json['tier_seed'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TournamentTierModelToJson(
        TournamentTierModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournament_id': instance.tournamentId,
      'team_id': instance.teamId,
      'tier': instance.tierValue,
      'group_position': instance.groupPosition,
      'group_points': instance.groupPoints,
      'point_differential': instance.pointDifferential,
      'tier_seed': instance.tierSeed,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
