import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teamapp3/features/profile/bloc/profile_event.dart';
import 'package:teamapp3/features/profile/bloc/profile_state.dart';
import 'package:teamapp3/features/profile/data/repositories/profile_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository(),
        super(const ProfileState()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfilePictureUploadRequested>(_onProfilePictureUploadRequested);
    on<ProfilePictureDeleteRequested>(_onProfilePictureDeleteRequested);
    on<MyTournamentsLoadRequested>(_onMyTournamentsLoadRequested);
    on<ProfileRefreshRequested>(_onProfileRefreshRequested);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.toLoading());

    try {
      final profile = await _profileRepository.getUserProfile(event.userId);
      emit(state.toSuccess(profile: profile));
    } catch (e) {
      emit(state.toError('Failed to load profile: ${e.toString()}'));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.toUpdating());

    try {
      final updatedProfile = await _profileRepository.updateProfile(
        userId: event.userId,
        fullName: event.fullName,
        bio: event.bio,
        phone: event.phone,
        location: event.location,
        dateOfBirth: event.dateOfBirth,
      );
      emit(state.toSuccess(profile: updatedProfile));
    } catch (e) {
      emit(state.toError('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<void> _onProfilePictureUploadRequested(
    ProfilePictureUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.toUploadingPicture());

    try {
      await _profileRepository.uploadProfilePicture(
        userId: event.userId,
        imageFile: event.imageFile,
      );
      
      // Reload profile to get updated picture URL
      final updatedProfile = await _profileRepository.getUserProfile(event.userId);
      emit(state.toSuccess(profile: updatedProfile));
    } catch (e) {
      emit(state.toError('Failed to upload profile picture: ${e.toString()}'));
    }
  }

  Future<void> _onProfilePictureDeleteRequested(
    ProfilePictureDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.toUpdating());

    try {
      await _profileRepository.deleteProfilePicture(event.userId);
      
      // Reload profile to get updated data
      final updatedProfile = await _profileRepository.getUserProfile(event.userId);
      emit(state.toSuccess(profile: updatedProfile));
    } catch (e) {
      emit(state.toError('Failed to delete profile picture: ${e.toString()}'));
    }
  }

  Future<void> _onMyTournamentsLoadRequested(
    MyTournamentsLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final tournaments = await _profileRepository.getMyTournaments(event.userId);
      emit(state.toSuccess(myTournaments: tournaments));
    } catch (e) {
      emit(state.toError('Failed to load tournaments: ${e.toString()}'));
    }
  }

  Future<void> _onProfileRefreshRequested(
    ProfileRefreshRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final profile = await _profileRepository.getUserProfile(event.userId);
      final tournaments = await _profileRepository.getMyTournaments(event.userId);
      emit(state.toSuccess(profile: profile, myTournaments: tournaments));
    } catch (e) {
      emit(state.toError('Failed to refresh profile: ${e.toString()}'));
    }
  }
} 