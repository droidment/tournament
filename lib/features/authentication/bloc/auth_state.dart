part of 'auth_bloc.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading,
  error,
  passwordResetSent,
}

class AuthState extends Equatable {
  const AuthState._({
    this.status = AuthStatus.unknown,
    this.user,
    this.userProfile,
    this.errorMessage,
  });

  const AuthState.unknown() : this._();

  const AuthState.authenticated({
    required supabase.User user,
    UserModel? userProfile,
  }) : this._(
          status: AuthStatus.authenticated,
          user: user,
          userProfile: userProfile,
        );

  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  const AuthState.loading({
    supabase.User? user,
    UserModel? userProfile,
  }) : this._(
          status: AuthStatus.loading,
          user: user,
          userProfile: userProfile,
        );

  const AuthState.error(
    String errorMessage, {
    supabase.User? user,
    UserModel? userProfile,
  }) : this._(
          status: AuthStatus.error,
          errorMessage: errorMessage,
          user: user,
          userProfile: userProfile,
        );

  const AuthState.passwordResetSent()
      : this._(status: AuthStatus.passwordResetSent);

  final AuthStatus status;
  final supabase.User? user;
  final UserModel? userProfile;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, user, userProfile, errorMessage];
}

// Helper classes for type safety
class AuthenticatedState extends AuthState {
  const AuthenticatedState({
    required supabase.User user,
    UserModel? userProfile,
  }) : super._(
          status: AuthStatus.authenticated,
          user: user,
          userProfile: userProfile,
        );
} 