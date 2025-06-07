import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'tournament_group_model.g.dart';

@JsonSerializable()
class TournamentGroupModel extends Equatable {
  const TournamentGroupModel({
    required this.id,
    required this.tournamentId,
    required this.groupName,
    required this.groupNumber,
    required this.teamIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentGroupModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentGroupModelFromJson(json);

  final String id;
  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  @JsonKey(name: 'group_name')
  final String groupName;
  @JsonKey(name: 'group_number')
  final int groupNumber;
  @JsonKey(name: 'team_ids')
  final List<String> teamIds;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$TournamentGroupModelToJson(this);

  TournamentGroupModel copyWith({
    String? id,
    String? tournamentId,
    String? groupName,
    int? groupNumber,
    List<String>? teamIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentGroupModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      groupName: groupName ?? this.groupName,
      groupNumber: groupNumber ?? this.groupNumber,
      teamIds: teamIds ?? this.teamIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        groupName,
        groupNumber,
        teamIds,
        createdAt,
        updatedAt,
      ];
} 