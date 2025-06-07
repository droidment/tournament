import 'package:equatable/equatable.dart';
import 'package:teamapp3/core/models/team_model.dart';

enum TeamBlocStatus {
  initial,
  loading,
  success,
  error,
  creating,
  updating,
  deleting,
}

class TeamState extends Equatable {

  const TeamState({
    this.status = TeamBlocStatus.initial,
    this.teams = const [],
    this.selectedTeam,
    this.errorMessage,
  });
  final TeamBlocStatus status;
  final List<TeamModel> teams;
  final TeamModel? selectedTeam;
  final String? errorMessage;

  TeamState copyWith({
    TeamBlocStatus? status,
    List<TeamModel>? teams,
    TeamModel? selectedTeam,
    String? errorMessage,
  }) {
    return TeamState(
      status: status ?? this.status,
      teams: teams ?? this.teams,
      selectedTeam: selectedTeam ?? this.selectedTeam,
      errorMessage: errorMessage,
    );
  }

  TeamState toLoading() {
    return copyWith(
      status: TeamBlocStatus.loading,
    );
  }

  TeamState toCreating() {
    return copyWith(
      status: TeamBlocStatus.creating,
    );
  }

  TeamState toUpdating() {
    return copyWith(
      status: TeamBlocStatus.updating,
    );
  }

  TeamState toDeleting() {
    return copyWith(
      status: TeamBlocStatus.deleting,
    );
  }

  TeamState toSuccess({
    List<TeamModel>? teams,
    TeamModel? selectedTeam,
  }) {
    return copyWith(
      status: TeamBlocStatus.success,
      teams: teams ?? this.teams,
      selectedTeam: selectedTeam,
    );
  }

  TeamState toError(String message) {
    return copyWith(
      status: TeamBlocStatus.error,
      errorMessage: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        teams,
        selectedTeam,
        errorMessage,
      ];
} 