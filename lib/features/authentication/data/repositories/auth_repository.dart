import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamapp3/core/models/user_model.dart';
import 'package:teamapp3/core/services/supabase_service.dart';
import 'package:teamapp3/core/constants/supabase_constants.dart';

class AuthRepository {

  AuthRepository({
    SupabaseService? supabaseService,
    GoogleSignIn? googleSignIn,
  })  : _supabaseService = supabaseService ?? SupabaseService.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();
  final SupabaseService _supabaseService;
  final GoogleSignIn _googleSignIn;

  // Current user getters
  User? get currentUser => _supabaseService.currentUser;
  bool get isAuthenticated => _supabaseService.isAuthenticated;
  String? get currentUserId => _supabaseService.currentUserId;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabaseService.authStateChanges;

  // Sign up with email
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Failed to get Google auth tokens');
      }

      final response = await _supabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabaseService.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabaseService.client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) return null;

      final response = await _supabaseService
          .from(SupabaseConstants.usersTable)
          .select()
          .eq('id', currentUserId!)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (bio != null) updates['bio'] = bio;

      final response = await _supabaseService
          .from(SupabaseConstants.usersTable)
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Upload avatar
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    try {
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}';
      await _supabaseService.storage
          .from(SupabaseConstants.avatarsBucket)
          .upload(fileName, file);

      final url = _supabaseService.storage
          .from(SupabaseConstants.avatarsBucket)
          .getPublicUrl(fileName);

      // Update user profile with new avatar URL
      await updateUserProfile(userId: userId);
      await _supabaseService
          .from(SupabaseConstants.usersTable)
          .update({'avatar_url': url}).eq('id', userId);

      return url;
    } catch (e) {
      rethrow;
    }
  }
} 