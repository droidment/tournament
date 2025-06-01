import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tournament_model.g.dart';

enum TournamentFormat {
  @JsonValue('round_robin')
  roundRobin,
  @JsonValue('swiss_ladder')
  swissLadder,
  @JsonValue('single_elimination')
  singleElimination,
  @JsonValue('double_elimination')
  doubleElimination,
  @JsonValue('custom_bracket')
  customBracket,
}

enum TournamentStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('upcoming')
  upcoming,
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

@JsonSerializable()
class TournamentModel extends Equatable {
  const TournamentModel({
    required this.id,
    required this.name,
    required this.organizerId,
    required this.format,
    required this.status,
    this.description,
    this.location,
    this.startDate,
    this.endDate,
    this.registrationDeadline,
    this.maxTeams,
    this.entryFee,
    this.rules,
    this.welcomeMessage,
    this.imageUrl,
    this.isPublic = true,
    this.allowSelfRegistration = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  @JsonKey(name: 'organizer_id')
  final String organizerId;
  final TournamentFormat format;
  final TournamentStatus status;
  final String? description;
  final String? location;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @JsonKey(name: 'registration_deadline')
  final DateTime? registrationDeadline;
  @JsonKey(name: 'max_teams')
  final int? maxTeams;
  @JsonKey(name: 'entry_fee')
  final double? entryFee;
  final String? rules;
  @JsonKey(name: 'welcome_message')
  final String? welcomeMessage;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'allow_self_registration')
  final bool allowSelfRegistration;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);

  Map<String, dynamic> toJson() => _$TournamentModelToJson(this);

  TournamentModel copyWith({
    String? id,
    String? name,
    String? organizerId,
    TournamentFormat? format,
    TournamentStatus? status,
    String? description,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? maxTeams,
    double? entryFee,
    String? rules,
    String? welcomeMessage,
    String? imageUrl,
    bool? isPublic,
    bool? allowSelfRegistration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      organizerId: organizerId ?? this.organizerId,
      format: format ?? this.format,
      status: status ?? this.status,
      description: description ?? this.description,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      maxTeams: maxTeams ?? this.maxTeams,
      entryFee: entryFee ?? this.entryFee,
      rules: rules ?? this.rules,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublic: isPublic ?? this.isPublic,
      allowSelfRegistration: allowSelfRegistration ?? this.allowSelfRegistration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        organizerId,
        format,
        status,
        description,
        location,
        startDate,
        endDate,
        registrationDeadline,
        maxTeams,
        entryFee,
        rules,
        welcomeMessage,
        imageUrl,
        isPublic,
        allowSelfRegistration,
        createdAt,
        updatedAt,
      ];
} 