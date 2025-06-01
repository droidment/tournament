// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_resource_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentResourceModel _$TournamentResourceModelFromJson(
        Map<String, dynamic> json) =>
    TournamentResourceModel(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      location: json['location'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TournamentResourceModelToJson(
        TournamentResourceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournament_id': instance.tournamentId,
      'name': instance.name,
      'type': instance.type,
      'description': instance.description,
      'capacity': instance.capacity,
      'location': instance.location,
      'is_active': instance.isActive,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
