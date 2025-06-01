import 'package:equatable/equatable.dart';
import '../../../../core/models/tournament_resource_model.dart';

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
  final ResourceBlocStatus status;
  final List<TournamentResourceModel> resources;
  final List<String> resourceTypes;
  final TournamentResourceModel? selectedResource;
  final String? errorMessage;

  const ResourceState({
    this.status = ResourceBlocStatus.initial,
    this.resources = const [],
    this.resourceTypes = const [],
    this.selectedResource,
    this.errorMessage,
  });

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
      errorMessage: null,
    );
  }

  ResourceState toCreating() {
    return copyWith(
      status: ResourceBlocStatus.creating,
      errorMessage: null,
    );
  }

  ResourceState toUpdating() {
    return copyWith(
      status: ResourceBlocStatus.updating,
      errorMessage: null,
    );
  }

  ResourceState toDeleting() {
    return copyWith(
      status: ResourceBlocStatus.deleting,
      errorMessage: null,
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
      errorMessage: null,
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