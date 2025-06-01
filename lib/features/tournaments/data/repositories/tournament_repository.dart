import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tournament_model.dart';

class TournamentRepository {
  final SupabaseClient _supabaseClient;

  TournamentRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  Future<TournamentModel> createTournament({
    required String name,
    required String description,
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not authenticated');
    }

    final data = await _supabaseClient.from('tournaments').insert({
      'name': name,
      'description': description,
      'format': format,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'organizer_id': user.id,
      'status': 'draft',
    }).select().single();

    return TournamentModel.fromJson(data);
  }

  Future<TournamentModel?> getTournament(String id) async {
    final data = await _supabaseClient
        .from('tournaments')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return TournamentModel.fromJson(data);
  }

  Future<List<TournamentModel>> getUserTournaments() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not authenticated');
    }

    final data = await _supabaseClient
        .from('tournaments')
        .select()
        .eq('organizer_id', user.id)
        .order('created_at', ascending: false);

    return data.map((json) => TournamentModel.fromJson(json)).toList();
  }

  Future<TournamentModel> updateTournament({
    required String id,
    String? name,
    String? description,
    String? format,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (format != null) updateData['format'] = format;
    if (status != null) updateData['status'] = status;
    if (startDate != null) updateData['start_date'] = startDate.toIso8601String();
    if (endDate != null) updateData['end_date'] = endDate.toIso8601String();

    final data = await _supabaseClient
        .from('tournaments')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    return TournamentModel.fromJson(data);
  }

  Future<void> deleteTournament(String id) async {
    await _supabaseClient
        .from('tournaments')
        .delete()
        .eq('id', id);
  }
} 