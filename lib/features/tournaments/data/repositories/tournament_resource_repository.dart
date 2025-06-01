import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/tournament_resource_model.dart';

class TournamentResourceRepository {
  final SupabaseClient _supabaseClient;

  TournamentResourceRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  Future<TournamentResourceModel> createResource({
    required String tournamentId,
    required String name,
    required String type,
    String? description,
    int? capacity,
    String? location,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not authenticated');
    }

    final insertData = {
      'tournament_id': tournamentId,
      'name': name,
      'type': type,
      'description': description,
      'capacity': capacity,
      'location': location,
      'created_by': user.id,
    };

    final data = await _supabaseClient
        .from('tournament_resources')
        .insert(insertData)
        .select()
        .single();

    return TournamentResourceModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<TournamentResourceModel>> getTournamentResources(String tournamentId) async {
    final data = await _supabaseClient
        .from('tournament_resources')
        .select()
        .eq('tournament_id', tournamentId)
        .eq('is_active', true)
        .order('name', ascending: true);

    return data.map((json) => TournamentResourceModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<TournamentResourceModel>> getResourcesByType(String tournamentId, String type) async {
    final data = await _supabaseClient
        .from('tournament_resources')
        .select()
        .eq('tournament_id', tournamentId)
        .eq('type', type)
        .eq('is_active', true)
        .order('name', ascending: true);

    return data.map((json) => TournamentResourceModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<TournamentResourceModel?> getResource(String resourceId) async {
    final data = await _supabaseClient
        .from('tournament_resources')
        .select()
        .eq('id', resourceId)
        .maybeSingle();

    if (data == null) return null;
    return TournamentResourceModel.fromJson(data as Map<String, dynamic>);
  }

  Future<TournamentResourceModel> updateResource({
    required String resourceId,
    String? name,
    String? type,
    String? description,
    int? capacity,
    String? location,
    bool? isActive,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (name != null) updateData['name'] = name;
    if (type != null) updateData['type'] = type;
    if (description != null) updateData['description'] = description;
    if (capacity != null) updateData['capacity'] = capacity;
    if (location != null) updateData['location'] = location;
    if (isActive != null) updateData['is_active'] = isActive;

    final data = await _supabaseClient
        .from('tournament_resources')
        .update(updateData)
        .eq('id', resourceId)
        .select()
        .single();

    return TournamentResourceModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteResource(String resourceId) async {
    await _supabaseClient
        .from('tournament_resources')
        .delete()
        .eq('id', resourceId);
  }

  Future<int> getResourceCount(String tournamentId) async {
    final data = await _supabaseClient
        .from('tournament_resources')
        .select('id')
        .eq('tournament_id', tournamentId)
        .eq('is_active', true);

    return data.length;
  }

  Future<List<String>> getResourceTypes(String tournamentId) async {
    final data = await _supabaseClient
        .from('tournament_resources')
        .select('type')
        .eq('tournament_id', tournamentId)
        .eq('is_active', true);

    final types = data.map((row) => row['type'] as String).toSet().toList();
    types.sort();
    return types;
  }
} 