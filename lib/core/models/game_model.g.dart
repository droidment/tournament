// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameModel _$GameModelFromJson(Map<String, dynamic> json) => GameModel(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      categoryId: json['category_id'] as String?,
      round: (json['round'] as num?)?.toInt(),
      roundName: json['round_name'] as String?,
      gameNumber: (json['game_number'] as num?)?.toInt(),
      team1Id: json['team1_id'] as String?,
      team2Id: json['team2_id'] as String?,
      resourceId: json['resource_id'] as String?,
      scheduledDate: json['scheduled_date'] == null
          ? null
          : DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: json['scheduled_time'] as String?,
      estimatedDuration: (json['estimated_duration'] as num?)?.toInt() ?? 60,
      status: $enumDecodeNullable(_$GameStatusEnumMap, json['status']) ??
          GameStatus.scheduled,
      winnerId: json['winner_id'] as String?,
      team1Score: (json['team1_score'] as num?)?.toInt(),
      team2Score: (json['team2_score'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      refereeNotes: json['referee_notes'] as String?,
      streamUrl: json['stream_url'] as String?,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$GameModelToJson(GameModel instance) => <String, dynamic>{
      'id': instance.id,
      'tournament_id': instance.tournamentId,
      'category_id': instance.categoryId,
      'round': instance.round,
      'round_name': instance.roundName,
      'game_number': instance.gameNumber,
      'team1_id': instance.team1Id,
      'team2_id': instance.team2Id,
      'resource_id': instance.resourceId,
      'scheduled_date': instance.scheduledDate?.toIso8601String(),
      'scheduled_time': instance.scheduledTime,
      'estimated_duration': instance.estimatedDuration,
      'status': _$GameStatusEnumMap[instance.status]!,
      'winner_id': instance.winnerId,
      'team1_score': instance.team1Score,
      'team2_score': instance.team2Score,
      'notes': instance.notes,
      'is_published': instance.isPublished,
      'referee_notes': instance.refereeNotes,
      'stream_url': instance.streamUrl,
      'created_by': instance.createdBy,
      'updated_by': instance.updatedBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
    };

const _$GameStatusEnumMap = {
  GameStatus.scheduled: 'scheduled',
  GameStatus.inProgress: 'in_progress',
  GameStatus.completed: 'completed',
  GameStatus.cancelled: 'cancelled',
  GameStatus.postponed: 'postponed',
  GameStatus.forfeit: 'forfeit',
};
