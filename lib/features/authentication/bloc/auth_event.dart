part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class _AuthStateChanged extends AuthEvent {
  const _AuthStateChanged(this.supabaseAuthState);

  final supabase.AuthState supabaseAuthState;

  @override
  List<Object> get props => [supabaseAuthState];
}

class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.fullName,
  });

  final String email;
  final String password;
  final String? fullName;

  @override
  List<Object?> get props => [email, password, fullName];
}

class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object> get props => [email, password];
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object> get props => [email];
}

class AuthProfileUpdateRequested extends AuthEvent {
  const AuthProfileUpdateRequested({
    this.fullName,
    this.phone,
    this.bio,
  });

  final String? fullName;
  final String? phone;
  final String? bio;

  @override
  List<Object?> get props => [fullName, phone, bio];
}

class AuthAvatarUploadRequested extends AuthEvent {
  const AuthAvatarUploadRequested({required this.file});

  final File file;

  @override
  List<Object> get props => [file];
} 