import 'package:equatable/equatable.dart';

abstract class ResourceEvent extends Equatable {
  const ResourceEvent();

  @override
  List<Object?> get props => [];
}

class ResourceCreateRequested extends ResourceEvent {
  final String tournamentId;
  final String name;
  final String type;
  final String? description;
  final int? capacity;
  final String? location;

  const ResourceCreateRequested({
    required this.tournamentId,
    required this.name,
    required this.type,
    this.description,
    this.capacity,
    this.location,
  });

  @override
  List<Object?> get props => [
        tournamentId,
        name,
        type,
        description,
        capacity,
        location,
      ];
}

class TournamentResourcesLoadRequested extends ResourceEvent {
  final String tournamentId;

  const TournamentResourcesLoadRequested(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
}

class ResourcesByTypeLoadRequested extends ResourceEvent {
  final String tournamentId;
  final String type;

  const ResourcesByTypeLoadRequested(this.tournamentId, this.type);

  @override
  List<Object?> get props => [tournamentId, type];
}

class ResourceUpdateRequested extends ResourceEvent {
  final String resourceId;
  final String? name;
  final String? type;
  final String? description;
  final int? capacity;
  final String? location;
  final bool? isActive;

  const ResourceUpdateRequested({
    required this.resourceId,
    this.name,
    this.type,
    this.description,
    this.capacity,
    this.location,
    this.isActive,
  });

  @override
  List<Object?> get props => [
        resourceId,
        name,
        type,
        description,
        capacity,
        location,
        isActive,
      ];
}

class ResourceDeleteRequested extends ResourceEvent {
  final String resourceId;

  const ResourceDeleteRequested(this.resourceId);

  @override
  List<Object?> get props => [resourceId];
}

class ResourceTypesLoadRequested extends ResourceEvent {
  final String tournamentId;

  const ResourceTypesLoadRequested(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
} 