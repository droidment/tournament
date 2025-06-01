import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/team_model.dart';

class TeamRepository {
  final SupabaseClient _supabaseClient;

  TeamRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  Future<TeamModel> createTeam({
    required String tournamentId,
    required String name,
    String? description,
    String? categoryId,
    String? contactEmail,
    String? contactPhone,
    int? seed,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not authenticated');
    }

    final insertData = {
      'tournament_id': tournamentId,
      'name': name,
      'description': description,
      'manager_id': user.id,
      'created_by': user.id,
      'updated_by': user.id,
      'category_id': categoryId,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'seed': seed,
    };

    final data = await _supabaseClient.from('teams').insert(insertData).select().single();
    return TeamModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TeamModel>> getTournamentTeams(String tournamentId) async {
    final data = await _supabaseClient
        .from('teams')
        .select()
        .eq('tournament_id', tournamentId)
        .eq('is_active', true)
        .order('name', ascending: true);

    return data.map((json) => TeamModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<TeamModel>> getCategoryTeams(String categoryId) async {
    final data = await _supabaseClient
        .from('teams')
        .select()
        .eq('category_id', categoryId)
        .eq('is_active', true)
        .order('name', ascending: true);

    return data.map((json) => TeamModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<TeamModel?> getTeam(String teamId) async {
    final data = await _supabaseClient
        .from('teams')
        .select()
        .eq('id', teamId)
        .maybeSingle();

    if (data == null) return null;
    return TeamModel.fromJson(data as Map<String, dynamic>);
  }

  Future<TeamModel> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? categoryId,
    String? contactEmail,
    String? contactPhone,
    int? seed,
    bool? isActive,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not authenticated');
    }

    final updateData = <String, dynamic>{};
    
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (categoryId != null) updateData['category_id'] = categoryId;
    if (contactEmail != null) updateData['contact_email'] = contactEmail;
    if (contactPhone != null) updateData['contact_phone'] = contactPhone;
    if (seed != null) updateData['seed'] = seed;
    if (isActive != null) updateData['is_active'] = isActive;
    
    // Always set updated_by when updating
    updateData['updated_by'] = user.id;

    final data = await _supabaseClient
        .from('teams')
        .update(updateData)
        .eq('id', teamId)
        .select()
        .single();

    return TeamModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteTeam(String teamId) async {
    await _supabaseClient
        .from('teams')
        .delete()
        .eq('id', teamId);
  }

  Future<List<TeamModel>> getUserTeams(String userId) async {
    final data = await _supabaseClient
        .from('teams')
        .select()
        .eq('manager_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return data.map((json) => TeamModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<int> getTeamCount(String tournamentId) async {
    final data = await _supabaseClient
        .from('teams')
        .select('id')
        .eq('tournament_id', tournamentId)
        .eq('is_active', true);

    return data.length;
  }

  Future<int> getCategoryTeamCount(String categoryId) async {
    final data = await _supabaseClient
        .from('teams')
        .select('id')
        .eq('category_id', categoryId)
        .eq('is_active', true);

    return data.length;
  }
} 