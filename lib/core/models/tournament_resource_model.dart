import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tournament_resource_model.g.dart';

@JsonSerializable()
class TournamentResourceModel extends Equatable {

  factory TournamentResourceModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentResourceModelFromJson(json);
  const TournamentResourceModel({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.type,
    this.description,
    this.capacity,
    this.location,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  final String name;
  final String type; // 'court', 'field', 'table', 'pitch', etc.
  final String? description;
  final int? capacity; // Max players/teams that can use this resource
  final String? location; // Physical location description
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$TournamentResourceModelToJson(this);

  TournamentResourceModel copyWith({
    String? id,
    String? tournamentId,
    String? name,
    String? type,
    String? description,
    int? capacity,
    String? location,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentResourceModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      capacity: capacity ?? this.capacity,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        name,
        type,
        description,
        capacity,
        location,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      ];
} 