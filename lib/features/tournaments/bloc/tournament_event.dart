import 'package:equatable/equatable.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';

abstract class TournamentEvent extends Equatable {
  const TournamentEvent();

  @override
  List<Object?> get props => [];
}

class TournamentCreateRequested extends TournamentEvent {
  final String name;
  final String? description;
  final TournamentFormat format;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final int? maxTeams;
  final DateTime? registrationDeadline;
  final String? rules;
  final String? prizeDescription;

  const TournamentCreateRequested({
    required this.name,
    this.description,
    required this.format,
    required this.startDate,
    required this.endDate,
    this.location,
    this.maxTeams,
    this.registrationDeadline,
    this.rules,
    this.prizeDescription,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        format,
        startDate,
        endDate,
        location,
        maxTeams,
        registrationDeadline,
        rules,
        prizeDescription,
      ];
}

class TournamentLoadRequested extends TournamentEvent {
  final String tournamentId;

  const TournamentLoadRequested(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
}

class UserTournamentsLoadRequested extends TournamentEvent {
  const UserTournamentsLoadRequested();
}

class TournamentUpdateRequested extends TournamentEvent {
  final String tournamentId;
  final String? name;
  final String? description;
  final TournamentFormat? format;
  final TournamentStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final int? maxTeams;
  final DateTime? registrationDeadline;
  final String? rules;
  final String? prizeDescription;

  const TournamentUpdateRequested({
    required this.tournamentId,
    this.name,
    this.description,
    this.format,
    this.status,
    this.startDate,
    this.endDate,
    this.location,
    this.maxTeams,
    this.registrationDeadline,
    this.rules,
    this.prizeDescription,
  });

  @override
  List<Object?> get props => [
        tournamentId,
        name,
        description,
        format,
        status,
        startDate,
        endDate,
        location,
        maxTeams,
        registrationDeadline,
        rules,
        prizeDescription,
      ];
}

class TournamentDeleteRequested extends TournamentEvent {
  final String tournamentId;

  const TournamentDeleteRequested(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
} 