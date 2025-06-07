// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentGroupModel _$TournamentGroupModelFromJson(
        Map<String, dynamic> json) =>
    TournamentGroupModel(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      groupName: json['group_name'] as String,
      groupNumber: (json['group_number'] as num).toInt(),
      teamIds:
          (json['team_ids'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TournamentGroupModelToJson(
        TournamentGroupModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournament_id': instance.tournamentId,
      'group_name': instance.groupName,
      'group_number': instance.groupNumber,
      'team_ids': instance.teamIds,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
