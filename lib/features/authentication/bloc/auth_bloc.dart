import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:teamapp3/core/models/user_model.dart';
import 'package:teamapp3/features/authentication/data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late StreamSubscription<supabase.AuthState> _authStateSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    
    on<_AuthStateChanged>(_onAuthStateChanged);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthAvatarUploadRequested>(_onAvatarUploadRequested);

    _authStateSubscription = _authRepository.authStateChanges.listen(
      (supabaseAuthState) => add(_AuthStateChanged(supabaseAuthState)),
    );
  }

  void _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    switch (event.supabaseAuthState.event) {
      case supabase.AuthChangeEvent.signedIn:
        final userProfile = await _authRepository.getCurrentUserProfile();
        emit(AuthState.authenticated(
          user: event.supabaseAuthState.session!.user,
          userProfile: userProfile,
        ));
        break;
      case supabase.AuthChangeEvent.signedOut:
        emit(const AuthState.unauthenticated());
        break;
      case supabase.AuthChangeEvent.userUpdated:
        final userProfile = await _authRepository.getCurrentUserProfile();
        emit(AuthState.authenticated(
          user: event.supabaseAuthState.session!.user,
          userProfile: userProfile,
        ));
        break;
      default:
        break;
    }
  }

  void _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signUpWithEmail(
        email: event.email,
        password: event.password,
        fullName: event.fullName,
      );
      // User will be automatically signed in after email verification
    } catch (error) {
      emit(AuthState.error(error.toString()));
    }
  }

  void _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      // User state will be updated through auth state stream
    } catch (error) {
      emit(AuthState.error(error.toString()));
    }
  }

  void _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.signInWithGoogle();
      // User state will be updated through auth state stream
    } catch (error) {
      emit(AuthState.error(error.toString()));
    }
  }

  void _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      // User state will be updated through auth state stream
    } catch (error) {
      emit(AuthState.error(error.toString()));
    }
  }

  void _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      await _authRepository.resetPassword(email: event.email);
      emit(const AuthState.passwordResetSent());
    } catch (error) {
      emit(AuthState.error(error.toString()));
    }
  }

  void _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated || state.user == null) return;

    emit(AuthState.loading(
      user: state.user,
      userProfile: state.userProfile,
    ));

    try {
      final updatedProfile = await _authRepository.updateUserProfile(
        userId: state.user!.id,
        fullName: event.fullName,
        phone: event.phone,
        bio: event.bio,
      );

      emit(AuthState.authenticated(
        user: state.user!,
        userProfile: updatedProfile,
      ));
    } catch (error) {
      emit(AuthState.error(
        error.toString(),
        user: state.user,
        userProfile: state.userProfile,
      ));
    }
  }

  void _onAvatarUploadRequested(
    AuthAvatarUploadRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status != AuthStatus.authenticated || state.user == null) return;

    emit(AuthState.loading(
      user: state.user,
      userProfile: state.userProfile,
    ));

    try {
      await _authRepository.uploadAvatar(
        userId: state.user!.id,
        file: event.file,
      );

      // Refresh user profile to get updated avatar URL
      final updatedProfile = await _authRepository.getCurrentUserProfile();

      emit(AuthState.authenticated(
        user: state.user!,
        userProfile: updatedProfile,
      ));
    } catch (error) {
      emit(AuthState.error(
        error.toString(),
        user: state.user,
        userProfile: state.userProfile,
      ));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
} 