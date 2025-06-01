import 'package:json_annotation/json_annotation.dart';

part 'user_profile_model.g.dart';

@JsonSerializable()
class UserProfileModel {
  final String id;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? location;
  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // Tournament-related fields
  @JsonKey(name: 'tournament_roles')
  final List<TournamentRole> tournamentRoles;
  @JsonKey(name: 'tournaments_created')
  final int tournamentsCreated;
  @JsonKey(name: 'tournaments_joined')
  final int tournamentsJoined;

  const UserProfileModel({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.location,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    this.tournamentRoles = const [],
    this.tournamentsCreated = 0,
    this.tournamentsJoined = 0,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);

  UserProfileModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? location,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TournamentRole>? tournamentRoles,
    int? tournamentsCreated,
    int? tournamentsJoined,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tournamentRoles: tournamentRoles ?? this.tournamentRoles,
      tournamentsCreated: tournamentsCreated ?? this.tournamentsCreated,
      tournamentsJoined: tournamentsJoined ?? this.tournamentsJoined,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileModel &&
        other.id == id &&
        other.email == email &&
        other.fullName == fullName &&
        other.avatarUrl == avatarUrl &&
        other.bio == bio &&
        other.phone == phone &&
        other.location == location &&
        other.dateOfBirth == dateOfBirth;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      fullName,
      avatarUrl,
      bio,
      phone,
      location,
      dateOfBirth,
    );
  }
}

@JsonSerializable()
class TournamentRole {
  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  @JsonKey(name: 'tournament_name')
  final String tournamentName;
  final UserRole role;
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;

  const TournamentRole({
    required this.tournamentId,
    required this.tournamentName,
    required this.role,
    required this.joinedAt,
  });

  factory TournamentRole.fromJson(Map<String, dynamic> json) =>
      _$TournamentRoleFromJson(json);

  Map<String, dynamic> toJson() => _$TournamentRoleToJson(this);
}

enum UserRole {
  @JsonValue('organizer')
  organizer,
  @JsonValue('admin')
  admin,
  @JsonValue('team_manager')
  teamManager,
  @JsonValue('player')
  player,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.organizer:
        return 'Organizer';
      case UserRole.admin:
        return 'Admin';
      case UserRole.teamManager:
        return 'Team Manager';
      case UserRole.player:
        return 'Player';
    }
  }

  String get description {
    switch (this) {
      case UserRole.organizer:
        return 'Can create and manage tournaments';
      case UserRole.admin:
        return 'Can assist in tournament management';
      case UserRole.teamManager:
        return 'Can manage team registrations and rosters';
      case UserRole.player:
        return 'Can participate in tournaments';
    }
  }
} 