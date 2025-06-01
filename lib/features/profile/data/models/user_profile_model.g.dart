// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) =>
    UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      location: json['location'] as String?,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tournamentRoles: (json['tournament_roles'] as List<dynamic>?)
              ?.map((e) => TournamentRole.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tournamentsCreated: (json['tournaments_created'] as num?)?.toInt() ?? 0,
      tournamentsJoined: (json['tournaments_joined'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$UserProfileModelToJson(UserProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'avatar_url': instance.avatarUrl,
      'bio': instance.bio,
      'phone': instance.phone,
      'location': instance.location,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'tournament_roles': instance.tournamentRoles,
      'tournaments_created': instance.tournamentsCreated,
      'tournaments_joined': instance.tournamentsJoined,
    };

TournamentRole _$TournamentRoleFromJson(Map<String, dynamic> json) =>
    TournamentRole(
      tournamentId: json['tournament_id'] as String,
      tournamentName: json['tournament_name'] as String,
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$TournamentRoleToJson(TournamentRole instance) =>
    <String, dynamic>{
      'tournament_id': instance.tournamentId,
      'tournament_name': instance.tournamentName,
      'role': _$UserRoleEnumMap[instance.role]!,
      'joined_at': instance.joinedAt.toIso8601String(),
    };

const _$UserRoleEnumMap = {
  UserRole.organizer: 'organizer',
  UserRole.admin: 'admin',
  UserRole.teamManager: 'team_manager',
  UserRole.player: 'player',
};
