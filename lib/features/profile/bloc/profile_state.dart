import 'package:equatable/equatable.dart';
import 'package:teamapp3/features/profile/data/models/user_profile_model.dart';

enum ProfileStatus {
  initial,
  loading,
  success,
  error,
  updating,
  uploadingPicture,
}

class ProfileState extends Equatable {

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.myTournaments = const [],
    this.errorMessage,
    this.isUpdating = false,
    this.isUploadingPicture = false,
  });
  final ProfileStatus status;
  final UserProfileModel? profile;
  final List<Map<String, dynamic>> myTournaments;
  final String? errorMessage;
  final bool isUpdating;
  final bool isUploadingPicture;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfileModel? profile,
    List<Map<String, dynamic>>? myTournaments,
    String? errorMessage,
    bool? isUpdating,
    bool? isUploadingPicture,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      myTournaments: myTournaments ?? this.myTournaments,
      errorMessage: errorMessage,
      isUpdating: isUpdating ?? this.isUpdating,
      isUploadingPicture: isUploadingPicture ?? this.isUploadingPicture,
    );
  }

  ProfileState clearError() {
    return copyWith(
      
    );
  }

  ProfileState toLoading() {
    return copyWith(
      status: ProfileStatus.loading,
    );
  }

  ProfileState toUpdating() {
    return copyWith(
      status: ProfileStatus.updating,
      isUpdating: true,
    );
  }

  ProfileState toUploadingPicture() {
    return copyWith(
      status: ProfileStatus.uploadingPicture,
      isUploadingPicture: true,
    );
  }

  ProfileState toSuccess({
    UserProfileModel? profile,
    List<Map<String, dynamic>>? myTournaments,
  }) {
    return copyWith(
      status: ProfileStatus.success,
      profile: profile ?? this.profile,
      myTournaments: myTournaments ?? this.myTournaments,
      isUpdating: false,
      isUploadingPicture: false,
    );
  }

  ProfileState toError(String message) {
    return copyWith(
      status: ProfileStatus.error,
      errorMessage: message,
      isUpdating: false,
      isUploadingPicture: false,
    );
  }

  @override
  List<Object?> get props => [
        status,
        profile,
        myTournaments,
        errorMessage,
        isUpdating,
        isUploadingPicture,
      ];
} 