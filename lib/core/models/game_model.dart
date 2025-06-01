import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'game_model.g.dart';

enum GameStatus {
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('postponed')
  postponed,
  @JsonValue('forfeit')
  forfeit,
}

@JsonSerializable()
class GameModel extends Equatable {
  const GameModel({
    required this.id,
    required this.tournamentId,
    this.categoryId,
    this.round,
    this.roundName,
    this.gameNumber,
    this.team1Id,
    this.team2Id,
    this.resourceId,
    this.scheduledDate,
    this.scheduledTime,
    this.estimatedDuration = 60,
    this.status = GameStatus.scheduled,
    this.winnerId,
    this.team1Score,
    this.team2Score,
    this.notes,
    this.isPublished = false,
    this.refereeNotes,
    this.streamUrl,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  @JsonKey(name: 'tournament_id')
  final String tournamentId;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  final int? round;
  @JsonKey(name: 'round_name')
  final String? roundName;
  @JsonKey(name: 'game_number')
  final int? gameNumber;
  @JsonKey(name: 'team1_id')
  final String? team1Id;
  @JsonKey(name: 'team2_id')
  final String? team2Id;
  @JsonKey(name: 'resource_id')
  final String? resourceId;
  @JsonKey(name: 'scheduled_date')
  final DateTime? scheduledDate;
  @JsonKey(name: 'scheduled_time')
  final String? scheduledTime; // TIME format from database
  @JsonKey(name: 'estimated_duration')
  final int estimatedDuration; // Duration in minutes
  final GameStatus status;
  @JsonKey(name: 'winner_id')
  final String? winnerId;
  @JsonKey(name: 'team1_score')
  final int? team1Score;
  @JsonKey(name: 'team2_score')
  final int? team2Score;
  final String? notes;
  @JsonKey(name: 'is_published')
  final bool isPublished;
  @JsonKey(name: 'referee_notes')
  final String? refereeNotes;
  @JsonKey(name: 'stream_url')
  final String? streamUrl;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'updated_by')
  final String? updatedBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'started_at')
  final DateTime? startedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  factory GameModel.fromJson(Map<String, dynamic> json) =>
      _$GameModelFromJson(json);

  Map<String, dynamic> toJson() => _$GameModelToJson(this);

  GameModel copyWith({
    String? id,
    String? tournamentId,
    String? categoryId,
    int? round,
    String? roundName,
    int? gameNumber,
    String? team1Id,
    String? team2Id,
    String? resourceId,
    DateTime? scheduledDate,
    String? scheduledTime,
    int? estimatedDuration,
    GameStatus? status,
    String? winnerId,
    int? team1Score,
    int? team2Score,
    String? notes,
    bool? isPublished,
    String? refereeNotes,
    String? streamUrl,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return GameModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      categoryId: categoryId ?? this.categoryId,
      round: round ?? this.round,
      roundName: roundName ?? this.roundName,
      gameNumber: gameNumber ?? this.gameNumber,
      team1Id: team1Id ?? this.team1Id,
      team2Id: team2Id ?? this.team2Id,
      resourceId: resourceId ?? this.resourceId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      notes: notes ?? this.notes,
      isPublished: isPublished ?? this.isPublished,
      refereeNotes: refereeNotes ?? this.refereeNotes,
      streamUrl: streamUrl ?? this.streamUrl,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        categoryId,
        round,
        roundName,
        gameNumber,
        team1Id,
        team2Id,
        resourceId,
        scheduledDate,
        scheduledTime,
        estimatedDuration,
        status,
        winnerId,
        team1Score,
        team2Score,
        notes,
        isPublished,
        refereeNotes,
        streamUrl,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
        startedAt,
        completedAt,
      ];

  // Helper methods
  bool get hasTeams => team1Id != null && team2Id != null;
  bool get isScheduled => scheduledDate != null && scheduledTime != null;
  bool get hasResource => resourceId != null;
  bool get hasResults => team1Score != null && team2Score != null;
  bool get isCompleted => status == GameStatus.completed;
  bool get canStart => hasTeams && isScheduled && status == GameStatus.scheduled;
  bool get canEdit => status == GameStatus.scheduled;

  String get statusDisplayName {
    switch (status) {
      case GameStatus.scheduled:
        return 'Scheduled';
      case GameStatus.inProgress:
        return 'In Progress';
      case GameStatus.completed:
        return 'Completed';
      case GameStatus.cancelled:
        return 'Cancelled';
      case GameStatus.postponed:
        return 'Postponed';
      case GameStatus.forfeit:
        return 'Forfeit';
    }
  }

  String get displayName {
    if (roundName != null) {
      return roundName!;
    }
    if (round != null) {
      return 'Round $round';
    }
    if (gameNumber != null) {
      return 'Game $gameNumber';
    }
    return 'Game ${id.substring(0, 8)}';
  }

  String? get scheduledDateTime {
    if (scheduledDate == null || scheduledTime == null) return null;
    return '${scheduledDate!.day}/${scheduledDate!.month}/${scheduledDate!.year} at $scheduledTime';
  }

  String? get resultSummary {
    if (!hasResults) return null;
    return '$team1Score - $team2Score';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GameModel{id: $id, tournamentId: $tournamentId, round: $round, status: $status, team1Id: $team1Id, team2Id: $team2Id}';
  }
} 