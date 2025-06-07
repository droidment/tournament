import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'tournament_tier_model.g.dart';

enum TournamentTier {
  pro('pro'),
  intermediate('intermediate'), 
  novice('novice');

  const TournamentTier(this.value);
  final String value;

  static TournamentTier fromString(String value) {
    return TournamentTier.values.firstWhere(
      (tier) => tier.value == value,
      orElse: () => TournamentTier.novice,
    );
  }
}

@JsonSerializable()
class TournamentTierModel extends Equatable {
  const TournamentTierModel({
    required this.id,
    required this.tournamentId,
    required this.teamId,
    required this.tierValue,
    required this.groupPosition,
    required this.groupPoints,
    required this.pointDifferential,
    required this.tierSeed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentTierModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentTierModelFromJson(json);

  final String id;
  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'tier')
  final String tierValue;
  @JsonKey(name: 'group_position')
  final int groupPosition;
  @JsonKey(name: 'group_points')
  final int groupPoints;
  @JsonKey(name: 'point_differential')
  final int pointDifferential;
  @JsonKey(name: 'tier_seed')
  final int tierSeed;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Convenience getter for enum
  TournamentTier get tier => TournamentTier.fromString(tierValue);

  Map<String, dynamic> toJson() => _$TournamentTierModelToJson(this);

  TournamentTierModel copyWith({
    String? id,
    String? tournamentId,
    String? teamId,
    String? tierValue,
    int? groupPosition,
    int? groupPoints,
    int? pointDifferential,
    int? tierSeed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentTierModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      teamId: teamId ?? this.teamId,
      tierValue: tierValue ?? this.tierValue,
      groupPosition: groupPosition ?? this.groupPosition,
      groupPoints: groupPoints ?? this.groupPoints,
      pointDifferential: pointDifferential ?? this.pointDifferential,
      tierSeed: tierSeed ?? this.tierSeed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        teamId,
        tierValue,
        groupPosition,
        groupPoints,
        pointDifferential,
        tierSeed,
        createdAt,
        updatedAt,
      ];
} 