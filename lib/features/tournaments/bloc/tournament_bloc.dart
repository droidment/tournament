import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_event.dart';
import 'package:teamapp3/features/tournaments/bloc/tournament_state.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_repository.dart';

class TournamentBloc extends Bloc<TournamentEvent, TournamentState> {
  final TournamentRepository _tournamentRepository;

  TournamentBloc({TournamentRepository? tournamentRepository})
      : _tournamentRepository = tournamentRepository ?? TournamentRepository(),
        super(const TournamentState()) {
    on<TournamentCreateRequested>(_onTournamentCreateRequested);
    on<TournamentLoadRequested>(_onTournamentLoadRequested);
    on<UserTournamentsLoadRequested>(_onUserTournamentsLoadRequested);
    on<TournamentUpdateRequested>(_onTournamentUpdateRequested);
    on<TournamentDeleteRequested>(_onTournamentDeleteRequested);
  }

  Future<void> _onTournamentCreateRequested(
    TournamentCreateRequested event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.toCreating());

    try {
      final tournament = await _tournamentRepository.createTournament(
        name: event.name,
        description: event.description ?? '',
        format: event.format.value,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(state.toSuccess(tournament: tournament));
    } catch (e) {
      emit(state.toError('Failed to create tournament: ${e.toString()}'));
    }
  }

  Future<void> _onTournamentLoadRequested(
    TournamentLoadRequested event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.toLoading());

    try {
      final tournament = await _tournamentRepository.getTournament(event.tournamentId);
      if (tournament != null) {
        emit(state.toSuccess(tournament: tournament));
      } else {
        emit(state.toError('Tournament not found'));
      }
    } catch (e) {
      emit(state.toError('Failed to load tournament: ${e.toString()}'));
    }
  }

  Future<void> _onUserTournamentsLoadRequested(
    UserTournamentsLoadRequested event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.toLoading());

    try {
      final tournaments = await _tournamentRepository.getUserTournaments();
      emit(state.toSuccess(tournaments: tournaments));
    } catch (e) {
      emit(state.toError('Failed to load tournaments: ${e.toString()}'));
    }
  }

  Future<void> _onTournamentUpdateRequested(
    TournamentUpdateRequested event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.toUpdating());

    try {
      final tournament = await _tournamentRepository.updateTournament(
        id: event.tournamentId,
        name: event.name,
        description: event.description,
        format: event.format?.value,
        status: event.status?.value,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(state.toSuccess(tournament: tournament));
    } catch (e) {
      emit(state.toError('Failed to update tournament: ${e.toString()}'));
    }
  }

  Future<void> _onTournamentDeleteRequested(
    TournamentDeleteRequested event,
    Emitter<TournamentState> emit,
  ) async {
    emit(state.toDeleting());

    try {
      await _tournamentRepository.deleteTournament(event.tournamentId);
      // Remove the deleted tournament from the list
      final updatedTournaments = state.tournaments
          .where((t) => t.id != event.tournamentId)
          .toList();
      emit(state.toSuccess(tournaments: updatedTournaments));
    } catch (e) {
      emit(state.toError('Failed to delete tournament: ${e.toString()}'));
    }
  }
} 