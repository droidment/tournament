import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_group_model.dart';

class TournamentGroupRepository {
  TournamentGroupRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;
      
  final SupabaseClient _supabaseClient;

  Future<TournamentGroupModel> createGroup(TournamentGroupModel group) async {
    final data = await _supabaseClient.from('tournament_groups').insert({
      'id': group.id,
      'tournament_id': group.tournamentId,
      'group_name': group.groupName,
      'group_number': group.groupNumber,
      'team_ids': group.teamIds,
    }).select().single();

    return TournamentGroupModel.fromJson(data);
  }

  Future<List<TournamentGroupModel>> createGroups(List<TournamentGroupModel> groups) async {
    if (groups.isEmpty) return [];

    final groupData = groups.map((group) => {
      'id': group.id,
      'tournament_id': group.tournamentId,
      'group_name': group.groupName,
      'group_number': group.groupNumber,
      'team_ids': group.teamIds,
    }).toList();

    final data = await _supabaseClient
        .from('tournament_groups')
        .insert(groupData)
        .select();

    return data.map(TournamentGroupModel.fromJson).toList();
  }

  Future<List<TournamentGroupModel>> getGroupsByTournament(String tournamentId) async {
    final data = await _supabaseClient
        .from('tournament_groups')
        .select()
        .eq('tournament_id', tournamentId)
        .order('group_number');

    return data.map(TournamentGroupModel.fromJson).toList();
  }

  Future<TournamentGroupModel?> getGroup(String groupId) async {
    final data = await _supabaseClient
        .from('tournament_groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();

    if (data == null) return null;
    return TournamentGroupModel.fromJson(data);
  }

  Future<TournamentGroupModel> updateGroup(TournamentGroupModel group) async {
    final data = await _supabaseClient
        .from('tournament_groups')
        .update({
          'group_name': group.groupName,
          'group_number': group.groupNumber,
          'team_ids': group.teamIds,
        })
        .eq('id', group.id)
        .select()
        .single();

    return TournamentGroupModel.fromJson(data);
  }

  Future<void> deleteGroup(String groupId) async {
    await _supabaseClient
        .from('tournament_groups')
        .delete()
        .eq('id', groupId);
  }

  Future<void> deleteGroupsByTournament(String tournamentId) async {
    await _supabaseClient
        .from('tournament_groups')
        .delete()
        .eq('tournament_id', tournamentId);
  }
} 