// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamModel _$TeamModelFromJson(Map<String, dynamic> json) => TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tournamentId: json['tournament_id'] as String,
      managerId: json['manager_id'] as String?,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      categoryId: json['category_id'] as String?,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      seed: (json['seed'] as num?)?.toInt(),
      color: TeamModel._colorFromJson(json['color'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TeamModelToJson(TeamModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tournament_id': instance.tournamentId,
      'manager_id': instance.managerId,
      'created_by': instance.createdBy,
      'updated_by': instance.updatedBy,
      'category_id': instance.categoryId,
      'logo_url': instance.logoUrl,
      'description': instance.description,
      'contact_email': instance.contactEmail,
      'contact_phone': instance.contactPhone,
      'seed': instance.seed,
      'color': TeamModel._colorToJson(instance.color),
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
