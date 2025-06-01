import 'package:flutter_bloc/flutter_bloc.dart';
import 'team_event.dart';
import 'team_state.dart';
import '../data/repositories/team_repository.dart';

class TeamBloc extends Bloc<TeamEvent, TeamState> {
  final TeamRepository _teamRepository;

  TeamBloc({TeamRepository? teamRepository})
      : _teamRepository = teamRepository ?? TeamRepository(),
        super(const TeamState()) {
    on<TeamCreateRequested>(_onTeamCreateRequested);
    on<TournamentTeamsLoadRequested>(_onTournamentTeamsLoadRequested);
    on<CategoryTeamsLoadRequested>(_onCategoryTeamsLoadRequested);
    on<TeamUpdateRequested>(_onTeamUpdateRequested);
    on<TeamDeleteRequested>(_onTeamDeleteRequested);
    on<UserTeamsLoadRequested>(_onUserTeamsLoadRequested);
  }

  Future<void> _onTeamCreateRequested(
    TeamCreateRequested event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.toCreating());

    try {
      final team = await _teamRepository.createTeam(
        tournamentId: event.tournamentId,
        name: event.name,
        description: event.description,
        categoryId: event.categoryId,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
        seed: event.seed,
      );

      // Load updated teams list
      final teams = await _teamRepository.getTournamentTeams(event.tournamentId);
      emit(state.toSuccess(teams: teams, selectedTeam: team));
    } catch (e) {
      emit(state.toError('Failed to create team: ${e.toString()}'));
    }
  }

  Future<void> _onTournamentTeamsLoadRequested(
    TournamentTeamsLoadRequested event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.toLoading());

    try {
      final teams = await _teamRepository.getTournamentTeams(event.tournamentId);
      emit(state.toSuccess(teams: teams));
    } catch (e) {
      emit(state.toError('Failed to load teams: ${e.toString()}'));
    }
  }

  Future<void> _onCategoryTeamsLoadRequested(
    CategoryTeamsLoadRequested event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.toLoading());

    try {
      final teams = await _teamRepository.getCategoryTeams(event.categoryId);
      emit(state.toSuccess(teams: teams));
    } catch (e) {
      emit(state.toError('Failed to load category teams: ${e.toString()}'));
    }
  }

  Future<void> _onTeamUpdateRequested(
    TeamUpdateRequested event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.toUpdating());

    try {
      final updatedTeam = await _teamRepository.updateTeam(
        teamId: event.teamId,
        name: event.name,
        description: event.description,
        categoryId: event.categoryId,
        contactEmail: event.contactEmail,
        contactPhone: event.contactPhone,
        seed: event.seed,
        isActive: event.isActive,
      );

      // Update the teams list
      final updatedTeams = state.teams.map((team) {
        return team.id == event.teamId ? updatedTeam : team;
      }).toList();

      emit(state.toSuccess(teams: updatedTeams, selectedTeam: updatedTeam));
    } catch (e) {
      emit(state.toError('Failed to update team: ${e.toString()}'));
    }
  }

  Future<void> _onTeamDeleteRequested(
    TeamDeleteRequested event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.toDeleting());

    try {
      await _teamRepository.deleteTeam(event.teamId);

      // Remove the deleted team from the list
      final updatedTeams = state.teams
          .where((team) => team.id != event.teamId)
          .toList();

      emit(state.toSuccess(teams: updatedTeams));
    } catch (e) {
      emit(state.toError('Failed to delete team: ${e.toString()}'));
    }
  }

  Future<void> _onUserTeamsLoadRequested(
    UserTeamsLoadRequested event,
    Emitter<TeamState> emit,
  ) async {
    emit(state.toLoading());

    try {
      final teams = await _teamRepository.getUserTeams(event.userId);
      emit(state.toSuccess(teams: teams));
    } catch (e) {
      emit(state.toError('Failed to load user teams: ${e.toString()}'));
    }
  }
} 