import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'team_model.g.dart';

@JsonSerializable()
class TeamModel extends Equatable {
  const TeamModel({
    required this.id,
    required this.name,
    required this.tournamentId,
    this.managerId,
    this.createdBy,
    this.updatedBy,
    this.categoryId,
    this.logoUrl,
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.seed,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  @JsonKey(name: 'manager_id')
  final String? managerId;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'updated_by')
  final String? updatedBy;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  final String? description;
  @JsonKey(name: 'contact_email')
  final String? contactEmail;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;
  final int? seed;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  factory TeamModel.fromJson(Map<String, dynamic> json) =>
      _$TeamModelFromJson(json);

  Map<String, dynamic> toJson() => _$TeamModelToJson(this);

  TeamModel copyWith({
    String? id,
    String? name,
    String? tournamentId,
    String? managerId,
    String? createdBy,
    String? updatedBy,
    String? categoryId,
    String? logoUrl,
    String? description,
    String? contactEmail,
    String? contactPhone,
    int? seed,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tournamentId: tournamentId ?? this.tournamentId,
      managerId: managerId ?? this.managerId,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      categoryId: categoryId ?? this.categoryId,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      seed: seed ?? this.seed,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        tournamentId,
        managerId,
        createdBy,
        updatedBy,
        categoryId,
        logoUrl,
        description,
        contactEmail,
        contactPhone,
        seed,
        isActive,
        createdAt,
        updatedAt,
      ];
} 