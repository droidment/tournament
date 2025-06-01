// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TournamentModel _$TournamentModelFromJson(Map<String, dynamic> json) =>
    TournamentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      organizerId: json['organizer_id'] as String,
      format: $enumDecode(_$TournamentFormatEnumMap, json['format']),
      status: $enumDecode(_$TournamentStatusEnumMap, json['status']),
      description: json['description'] as String?,
      location: json['location'] as String?,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      registrationDeadline: json['registration_deadline'] == null
          ? null
          : DateTime.parse(json['registration_deadline'] as String),
      maxTeams: (json['max_teams'] as num?)?.toInt(),
      entryFee: (json['entry_fee'] as num?)?.toDouble(),
      rules: json['rules'] as String?,
      welcomeMessage: json['welcome_message'] as String?,
      imageUrl: json['image_url'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      allowSelfRegistration: json['allow_self_registration'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TournamentModelToJson(TournamentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'organizer_id': instance.organizerId,
      'format': _$TournamentFormatEnumMap[instance.format]!,
      'status': _$TournamentStatusEnumMap[instance.status]!,
      'description': instance.description,
      'location': instance.location,
      'start_date': instance.startDate?.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'registration_deadline': instance.registrationDeadline?.toIso8601String(),
      'max_teams': instance.maxTeams,
      'entry_fee': instance.entryFee,
      'rules': instance.rules,
      'welcome_message': instance.welcomeMessage,
      'image_url': instance.imageUrl,
      'is_public': instance.isPublic,
      'allow_self_registration': instance.allowSelfRegistration,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$TournamentFormatEnumMap = {
  TournamentFormat.roundRobin: 'round_robin',
  TournamentFormat.swissLadder: 'swiss_ladder',
  TournamentFormat.singleElimination: 'single_elimination',
  TournamentFormat.doubleElimination: 'double_elimination',
  TournamentFormat.customBracket: 'custom_bracket',
};

const _$TournamentStatusEnumMap = {
  TournamentStatus.draft: 'draft',
  TournamentStatus.upcoming: 'upcoming',
  TournamentStatus.active: 'active',
  TournamentStatus.completed: 'completed',
  TournamentStatus.cancelled: 'cancelled',
};
