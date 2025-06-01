import 'package:equatable/equatable.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_model.dart';

enum TournamentBlocStatus {
  initial,
  loading,
  success,
  error,
  creating,
  updating,
  deleting,
}

class TournamentState extends Equatable {
  final TournamentBlocStatus status;
  final TournamentModel? tournament;
  final List<TournamentModel> tournaments;
  final String? errorMessage;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;

  const TournamentState({
    this.status = TournamentBlocStatus.initial,
    this.tournament,
    this.tournaments = const [],
    this.errorMessage,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
  });

  TournamentState copyWith({
    TournamentBlocStatus? status,
    TournamentModel? tournament,
    List<TournamentModel>? tournaments,
    String? errorMessage,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
  }) {
    return TournamentState(
      status: status ?? this.status,
      tournament: tournament ?? this.tournament,
      tournaments: tournaments ?? this.tournaments,
      errorMessage: errorMessage,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  TournamentState clearError() {
    return copyWith(
      errorMessage: null,
    );
  }

  TournamentState toLoading() {
    return copyWith(
      status: TournamentBlocStatus.loading,
      errorMessage: null,
    );
  }

  TournamentState toCreating() {
    return copyWith(
      status: TournamentBlocStatus.creating,
      isCreating: true,
      errorMessage: null,
    );
  }

  TournamentState toUpdating() {
    return copyWith(
      status: TournamentBlocStatus.updating,
      isUpdating: true,
      errorMessage: null,
    );
  }

  TournamentState toDeleting() {
    return copyWith(
      status: TournamentBlocStatus.deleting,
      isDeleting: true,
      errorMessage: null,
    );
  }

  TournamentState toSuccess({
    TournamentModel? tournament,
    List<TournamentModel>? tournaments,
  }) {
    return copyWith(
      status: TournamentBlocStatus.success,
      tournament: tournament ?? this.tournament,
      tournaments: tournaments ?? this.tournaments,
      errorMessage: null,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    );
  }

  TournamentState toError(String message) {
    return copyWith(
      status: TournamentBlocStatus.error,
      errorMessage: message,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tournament,
        tournaments,
        errorMessage,
        isCreating,
        isUpdating,
        isDeleting,
      ];
} 