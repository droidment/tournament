import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CategoryModel extends Equatable {
  final String id;
  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  final String name;
  final String? description;
  @JsonKey(name: 'max_teams')
  final int? maxTeams;
  @JsonKey(name: 'min_teams')
  final int minTeams;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'display_order')
  final int displayOrder;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.description,
    this.maxTeams,
    this.minTeams = 2,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  CategoryModel copyWith({
    String? id,
    String? tournamentId,
    String? name,
    String? description,
    int? maxTeams,
    int? minTeams,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      description: description ?? this.description,
      maxTeams: maxTeams ?? this.maxTeams,
      minTeams: minTeams ?? this.minTeams,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        name,
        description,
        maxTeams,
        minTeams,
        isActive,
        displayOrder,
        createdAt,
        updatedAt,
      ];
} 