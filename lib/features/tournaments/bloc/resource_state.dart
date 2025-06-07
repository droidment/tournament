import 'package:equatable/equatable.dart';
import 'package:teamapp3/core/models/tournament_resource_model.dart';

enum ResourceBlocStatus {
  initial,
  loading,
  success,
  error,
  creating,
  updating,
  deleting,
}

class ResourceState extends Equatable {

  const ResourceState({
    this.status = ResourceBlocStatus.initial,
    this.resources = const [],
    this.resourceTypes = const [],
    this.selectedResource,
    this.errorMessage,
  });
  final ResourceBlocStatus status;
  final List<TournamentResourceModel> resources;
  final List<String> resourceTypes;
  final TournamentResourceModel? selectedResource;
  final String? errorMessage;

  ResourceState copyWith({
    ResourceBlocStatus? status,
    List<TournamentResourceModel>? resources,
    List<String>? resourceTypes,
    TournamentResourceModel? selectedResource,
    String? errorMessage,
  }) {
    return ResourceState(
      status: status ?? this.status,
      resources: resources ?? this.resources,
      resourceTypes: resourceTypes ?? this.resourceTypes,
      selectedResource: selectedResource ?? this.selectedResource,
      errorMessage: errorMessage,
    );
  }

  ResourceState toLoading() {
    return copyWith(
      status: ResourceBlocStatus.loading,
    );
  }

  ResourceState toCreating() {
    return copyWith(
      status: ResourceBlocStatus.creating,
    );
  }

  ResourceState toUpdating() {
    return copyWith(
      status: ResourceBlocStatus.updating,
    );
  }

  ResourceState toDeleting() {
    return copyWith(
      status: ResourceBlocStatus.deleting,
    );
  }

  ResourceState toSuccess({
    List<TournamentResourceModel>? resources,
    List<String>? resourceTypes,
    TournamentResourceModel? selectedResource,
  }) {
    return copyWith(
      status: ResourceBlocStatus.success,
      resources: resources ?? this.resources,
      resourceTypes: resourceTypes ?? this.resourceTypes,
      selectedResource: selectedResource,
    );
  }

  ResourceState toError(String message) {
    return copyWith(
      status: ResourceBlocStatus.error,
      errorMessage: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        resources,
        resourceTypes,
        selectedResource,
        errorMessage,
      ];
} 