import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'tournament_model.g.dart';

enum TournamentFormat {
  roundRobin('roundRobin'),
  singleElimination('singleElimination'),
  doubleElimination('doubleElimination'),
  swiss('swiss'),
  tiered('tiered'),
  custom('custom');

  const TournamentFormat(this.value);
  final String value;

  static TournamentFormat fromString(String value) {
    return TournamentFormat.values.firstWhere(
      (format) => format.value == value,
      orElse: () => TournamentFormat.roundRobin,
    );
  }
}

enum TournamentStatus {
  draft('draft'),
  registration('registration'),
  inProgress('inProgress'),
  completed('completed'),
  cancelled('cancelled');

  const TournamentStatus(this.value);
  final String value;

  static TournamentStatus fromString(String value) {
    return TournamentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TournamentStatus.draft,
    );
  }
}

@JsonSerializable()
class TournamentModel extends Equatable {

  const TournamentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.formatValue,
    required this.statusValue,
    required this.startDate,
    required this.endDate,
    required this.organizerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TournamentModel.fromJson(Map<String, dynamic> json) =>
      _$TournamentModelFromJson(json);
  final String id;
  final String name;
  final String description;
  @JsonKey(name: 'format')
  final String formatValue;
  @JsonKey(name: 'status')
  final String statusValue;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  @JsonKey(name: 'organizer_id')
  final String organizerId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Convenience getters for enums
  TournamentFormat get format => TournamentFormat.fromString(formatValue);
  TournamentStatus get status => TournamentStatus.fromString(statusValue);
  
  // Backward compatibility getter
  String get createdBy => organizerId;

  Map<String, dynamic> toJson() => _$TournamentModelToJson(this);

  TournamentModel copyWith({
    String? id,
    String? name,
    String? description,
    String? formatValue,
    String? statusValue,
    DateTime? startDate,
    DateTime? endDate,
    String? organizerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      formatValue: formatValue ?? this.formatValue,
      statusValue: statusValue ?? this.statusValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      organizerId: organizerId ?? this.organizerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        formatValue,
        statusValue,
        startDate,
        endDate,
        organizerId,
        createdAt,
        updatedAt,
      ];
} 