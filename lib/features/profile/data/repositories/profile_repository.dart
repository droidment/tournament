import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamapp3/core/services/supabase_service.dart';
import 'package:teamapp3/features/profile/data/models/user_profile_model.dart';

class ProfileRepository {

  ProfileRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;
  final SupabaseService _supabaseService;

  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      // Try to get existing profile
      final response = await _supabaseService.client
          .from('users')
          .select('''
            id,
            email,
            full_name,
            avatar_url,
            bio,
            phone,
            location,
            date_of_birth,
            created_at,
            updated_at
          ''')
          .eq('id', userId)
          .maybeSingle();

      Map<String, dynamic> profileData;
      
      if (response == null) {
        // No profile exists, create one
        final userAuth = _supabaseService.currentUser;
        if (userAuth == null) {
          throw Exception('User not authenticated');
        }
        
        profileData = {
          'id': userId,
          'email': userAuth.email ?? '',
          'full_name': userAuth.userMetadata?['full_name'],
          'avatar_url': null,
          'bio': null,
          'phone': null,
          'location': null,
          'date_of_birth': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        // Insert new profile
        await _supabaseService.client
            .from('users')
            .insert(profileData);
      } else {
        profileData = response;
      }

      // Get tournament roles
      final tournamentRoles = await _getTournamentRoles(userId);
      
      // Get tournament counts
      final tournamentCounts = await _getTournamentCounts(userId);

      return UserProfileModel.fromJson({
        ...profileData,
        'tournament_roles': tournamentRoles.map((role) => role.toJson()).toList(),
        'tournaments_created': tournamentCounts['created'] ?? 0,
        'tournaments_joined': tournamentCounts['joined'] ?? 0,
      });
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<UserProfileModel> updateProfile({
    required String userId,
    String? fullName,
    String? bio,
    String? phone,
    String? location,
    DateTime? dateOfBirth,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (bio != null) updateData['bio'] = bio;
      if (phone != null) updateData['phone'] = phone;
      if (location != null) updateData['location'] = location;
      if (dateOfBirth != null) {
        updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      }

      await _supabaseService.client
          .from('users')
          .update(updateData)
          .eq('id', userId);

      return await getUserProfile(userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profile_pictures/$fileName';

      // Upload to Supabase Storage
      await _supabaseService.client.storage
          .from('avatars')
          .upload(filePath, imageFile);

      // Get public URL
      final publicUrl = _supabaseService.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Update user profile with new picture URL
      await _supabaseService.client
          .from('users')
          .update({
            'avatar_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  Future<void> deleteProfilePicture(String userId) async {
    try {
      // Get current profile to find the image path
      final profile = await getUserProfile(userId);
      
      if (profile.avatarUrl != null) {
        // Extract file path from URL
        final uri = Uri.parse(profile.avatarUrl!);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final filePath = pathSegments.sublist(pathSegments.length - 2).join('/');
          
          // Delete from storage
          await _supabaseService.client.storage
              .from('avatars')
              .remove([filePath]);
        }
      }

      // Update user profile to remove picture URL
      await _supabaseService.client
          .from('users')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete profile picture: $e');
    }
  }

  Future<List<TournamentRole>> _getTournamentRoles(String userId) async {
    try {
      final response = await _supabaseService.client
          .from('tournament_participants')
          .select('''
            tournament_id,
            role,
            joined_at,
            tournaments!inner(name)
          ''')
          .eq('user_id', userId);

      return response.map<TournamentRole>((data) => TournamentRole(
        tournamentId: data['tournament_id'] as String,
        tournamentName: data['tournaments']['name'] as String,
        role: UserRole.values.firstWhere(
          (role) => role.name == data['role'],
          orElse: () => UserRole.player,
        ),
        joinedAt: DateTime.parse(data['joined_at'] as String),
      ),).toList();
    } catch (e) {
      // If tables don't exist yet, return empty list
      return [];
    }
  }

  Future<Map<String, int>> _getTournamentCounts(String userId) async {
    try {
      // Get tournaments created count
      final createdResponse = await _supabaseService.client
          .from('tournaments')
          .select('id')
          .eq('created_by', userId);

      // Get tournaments joined count
      final joinedResponse = await _supabaseService.client
          .from('tournament_participants')
          .select('id')
          .eq('user_id', userId);

      return {
        'created': createdResponse.length,
        'joined': joinedResponse.length,
      };
    } catch (e) {
      // If tables don't exist yet, return zeros
      return {'created': 0, 'joined': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getMyTournaments(String userId) async {
    try {
      // Get tournaments where user is creator or participant
      final createdTournaments = await _supabaseService.client
          .from('tournaments')
          .select('''
            id,
            name,
            description,
            start_date,
            end_date,
            status,
            format,
            location
          ''')
          .eq('created_by', userId);

      final joinedTournamentsResponse = await _supabaseService.client
          .from('tournament_participants')
          .select('''
            role,
            joined_at,
            tournaments!inner(
              id,
              name,
              description,
              start_date,
              end_date,
              status,
              format,
              location
            )
          ''')
          .eq('user_id', userId);

      final joinedTournaments = joinedTournamentsResponse.map((data) => {
        ...Map<String, dynamic>.from(data['tournaments'] as Map),
        'my_role': data['role'],
        'joined_at': data['joined_at'],
      },).toList();

      // Mark created tournaments with organizer role
      final markedCreatedTournaments = createdTournaments.map((tournament) => {
        ...Map<String, dynamic>.from(tournament),
        'my_role': 'organizer',
        'joined_at': tournament['created_at'],
      },).toList();

      // Combine and deduplicate
      final allTournaments = <String, Map<String, dynamic>>{};
      
      for (final tournament in markedCreatedTournaments) {
        allTournaments[tournament['id'] as String] = tournament;
      }
      
      for (final tournament in joinedTournaments) {
        allTournaments[tournament['id'] as String] = tournament;
      }

      return allTournaments.values.toList()
        ..sort((a, b) => DateTime.parse(b['start_date'] as String)
            .compareTo(DateTime.parse(a['start_date'] as String)),);
    } catch (e) {
      // If tables don't exist yet, return empty list
      return [];
    }
  }
} 