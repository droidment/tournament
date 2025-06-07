import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_tier_model.dart';

class TournamentTierRepository {
  TournamentTierRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;
      
  final SupabaseClient _supabaseClient;

  Future<TournamentTierModel> createTierAssignment(TournamentTierModel tierAssignment) async {
    final data = await _supabaseClient.from('tournament_tiers').insert({
      'id': tierAssignment.id,
      'tournament_id': tierAssignment.tournamentId,
      'team_id': tierAssignment.teamId,
      'tier': tierAssignment.tierValue,
      'group_position': tierAssignment.groupPosition,
      'group_points': tierAssignment.groupPoints,
      'point_differential': tierAssignment.pointDifferential,
      'tier_seed': tierAssignment.tierSeed,
    }).select().single();

    return TournamentTierModel.fromJson(data);
  }

  Future<List<TournamentTierModel>> createTierAssignments(List<TournamentTierModel> tierAssignments) async {
    if (tierAssignments.isEmpty) return [];

    final tierData = tierAssignments.map((tier) => {
      'id': tier.id,
      'tournament_id': tier.tournamentId,
      'team_id': tier.teamId,
      'tier': tier.tierValue,
      'group_position': tier.groupPosition,
      'group_points': tier.groupPoints,
      'point_differential': tier.pointDifferential,
      'tier_seed': tier.tierSeed,
    }).toList();

    final data = await _supabaseClient
        .from('tournament_tiers')
        .insert(tierData)
        .select();

    return data.map(TournamentTierModel.fromJson).toList();
  }

  Future<List<TournamentTierModel>> getTiersByTournament(String tournamentId) async {
    final data = await _supabaseClient
        .from('tournament_tiers')
        .select()
        .eq('tournament_id', tournamentId)
        .order('tier_seed');

    return data.map(TournamentTierModel.fromJson).toList();
  }

  Future<List<TournamentTierModel>> getTiersByTournamentAndTier(
    String tournamentId, 
    TournamentTier tier,
  ) async {
    final data = await _supabaseClient
        .from('tournament_tiers')
        .select()
        .eq('tournament_id', tournamentId)
        .eq('tier', tier.value)
        .order('tier_seed');

    return data.map(TournamentTierModel.fromJson).toList();
  }

  Future<TournamentTierModel?> getTierAssignment(String tierAssignmentId) async {
    final data = await _supabaseClient
        .from('tournament_tiers')
        .select()
        .eq('id', tierAssignmentId)
        .maybeSingle();

    if (data == null) return null;
    return TournamentTierModel.fromJson(data);
  }

  Future<TournamentTierModel?> getTierAssignmentByTeam(
    String tournamentId,
    String teamId,
  ) async {
    final data = await _supabaseClient
        .from('tournament_tiers')
        .select()
        .eq('tournament_id', tournamentId)
        .eq('team_id', teamId)
        .maybeSingle();

    if (data == null) return null;
    return TournamentTierModel.fromJson(data);
  }

  Future<TournamentTierModel> updateTierAssignment(TournamentTierModel tierAssignment) async {
    final data = await _supabaseClient
        .from('tournament_tiers')
        .update({
          'tier': tierAssignment.tierValue,
          'group_position': tierAssignment.groupPosition,
          'group_points': tierAssignment.groupPoints,
          'point_differential': tierAssignment.pointDifferential,
          'tier_seed': tierAssignment.tierSeed,
        })
        .eq('id', tierAssignment.id)
        .select()
        .single();

    return TournamentTierModel.fromJson(data);
  }

  Future<void> deleteTierAssignment(String tierAssignmentId) async {
    await _supabaseClient
        .from('tournament_tiers')
        .delete()
        .eq('id', tierAssignmentId);
  }

  Future<void> deleteTiersByTournament(String tournamentId) async {
    await _supabaseClient
        .from('tournament_tiers')
        .delete()
        .eq('tournament_id', tournamentId);
  }

  Future<Map<String, int>> getTierCounts(String tournamentId) async {
    final data = await _supabaseClient
        .from('tournament_tiers')
        .select('tier')
        .eq('tournament_id', tournamentId);

    final counts = <String, int>{
      'pro': 0,
      'intermediate': 0,
      'novice': 0,
    };

    for (final row in data) {
      final tier = row['tier'] as String;
      counts[tier] = (counts[tier] ?? 0) + 1;
    }

    return counts;
  }
} 