import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/resource_event.dart';
import 'package:teamapp3/features/tournaments/bloc/resource_state.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_resource_repository.dart';

class ResourceBloc extends Bloc<ResourceEvent, ResourceState> {

  ResourceBloc({TournamentResourceRepository? resourceRepository})
      : _resourceRepository = resourceRepository ?? TournamentResourceRepository(),
        super(const ResourceState()) {
    on<ResourceCreateRequested>(_onResourceCreateRequested);
    on<TournamentResourcesLoadRequested>(_onTournamentResourcesLoadRequested);
    on<ResourcesByTypeLoadRequested>(_onResourcesByTypeLoadRequested);
    on<ResourceUpdateRequested>(_onResourceUpdateRequested);
    on<ResourceDeleteRequested>(_onResourceDeleteRequested);
    on<ResourceTypesLoadRequested>(_onResourceTypesLoadRequested);
  }
  final TournamentResourceRepository _resourceRepository;

  Future<void> _onResourceCreateRequested(
    ResourceCreateRequested event,
    Emitter<ResourceState> emit,
  ) async {
    emit(state.toCreating());

    try {
      final resource = await _resourceRepository.createResource(
        tournamentId: event.tournamentId,
        name: event.name,
        type: event.type,
        description: event.description,
        capacity: event.capacity,
        location: event.location,
      );

      // Load updated resources list
      final resources = await _resourceRepository.getTournamentResources(event.tournamentId);
      emit(state.toSuccess(resources: resources, selectedResource: resource));
    } catch (e) {
      emit(state.toError('Failed to create resource: ${e}'));
    }
  }

  Future<void> _onTournamentResourcesLoadRequested(
    TournamentResourcesLoadRequested event,
    Emitter<ResourceState> emit,
  ) async {
    emit(state.toLoading());

    try {
      final resources = await _resourceRepository.getTournamentResources(event.tournamentId);
      emit(state.toSuccess(resources: resources));
    } catch (e) {
      emit(state.toError('Failed to load resources: ${e}'));
    }
  }

  Future<void> _onResourcesByTypeLoadRequested(
    ResourcesByTypeLoadRequested event,
    Emitter<ResourceState> emit,
  ) async {
    emit(state.toLoading());

    try {
      final resources = await _resourceRepository.getResourcesByType(event.tournamentId, event.type);
      emit(state.toSuccess(resources: resources));
    } catch (e) {
      emit(state.toError('Failed to load resources by type: ${e}'));
    }
  }

  Future<void> _onResourceUpdateRequested(
    ResourceUpdateRequested event,
    Emitter<ResourceState> emit,
  ) async {
    emit(state.toUpdating());

    try {
      final updatedResource = await _resourceRepository.updateResource(
        resourceId: event.resourceId,
        name: event.name,
        type: event.type,
        description: event.description,
        capacity: event.capacity,
        location: event.location,
        isActive: event.isActive,
      );

      // Update the resources list
      final updatedResources = state.resources.map((resource) {
        return resource.id == event.resourceId ? updatedResource : resource;
      }).toList();

      emit(state.toSuccess(resources: updatedResources, selectedResource: updatedResource));
    } catch (e) {
      emit(state.toError('Failed to update resource: ${e}'));
    }
  }

  Future<void> _onResourceDeleteRequested(
    ResourceDeleteRequested event,
    Emitter<ResourceState> emit,
  ) async {
    emit(state.toDeleting());

    try {
      await _resourceRepository.deleteResource(event.resourceId);

      // Remove the deleted resource from the list
      final updatedResources = state.resources
          .where((resource) => resource.id != event.resourceId)
          .toList();

      emit(state.toSuccess(resources: updatedResources));
    } catch (e) {
      emit(state.toError('Failed to delete resource: ${e}'));
    }
  }

  Future<void> _onResourceTypesLoadRequested(
    ResourceTypesLoadRequested event,
    Emitter<ResourceState> emit,
  ) async {
    try {
      final types = await _resourceRepository.getResourceTypes(event.tournamentId);
      emit(state.toSuccess(resourceTypes: types));
    } catch (e) {
      emit(state.toError('Failed to load resource types: ${e}'));
    }
  }
} 