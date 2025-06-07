import 'package:equatable/equatable.dart';

abstract class ResourceEvent extends Equatable {
  const ResourceEvent();

  @override
  List<Object?> get props => [];
}

class ResourceCreateRequested extends ResourceEvent {

  const ResourceCreateRequested({
    required this.tournamentId,
    required this.name,
    required this.type,
    this.description,
    this.capacity,
    this.location,
  });
  final String tournamentId;
  final String name;
  final String type;
  final String? description;
  final int? capacity;
  final String? location;

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

  const TournamentResourcesLoadRequested(this.tournamentId);
  final String tournamentId;

  @override
  List<Object?> get props => [tournamentId];
}

class ResourcesByTypeLoadRequested extends ResourceEvent {

  const ResourcesByTypeLoadRequested(this.tournamentId, this.type);
  final String tournamentId;
  final String type;

  @override
  List<Object?> get props => [tournamentId, type];
}

class ResourceUpdateRequested extends ResourceEvent {

  const ResourceUpdateRequested({
    required this.resourceId,
    this.name,
    this.type,
    this.description,
    this.capacity,
    this.location,
    this.isActive,
  });
  final String resourceId;
  final String? name;
  final String? type;
  final String? description;
  final int? capacity;
  final String? location;
  final bool? isActive;

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

  const ResourceDeleteRequested(this.resourceId);
  final String resourceId;

  @override
  List<Object?> get props => [resourceId];
}

class ResourceTypesLoadRequested extends ResourceEvent {

  const ResourceTypesLoadRequested(this.tournamentId);
  final String tournamentId;

  @override
  List<Object?> get props => [tournamentId];
} 