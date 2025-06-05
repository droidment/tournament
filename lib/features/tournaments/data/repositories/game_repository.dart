import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/game_model.dart';

class GameRepository {
  final SupabaseClient _supabaseClient;

  GameRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  /// Create a new game
  Future<GameModel> createGame({
    required String tournamentId,
    String? categoryId,
    int? round,
    String? roundName,
    int? gameNumber,
    String? team1Id,
    String? team2Id,
    String? resourceId,
    DateTime? scheduledDate,
    String? scheduledTime,
    int estimatedDuration = 60,
    String? notes,
    bool isPublished = false,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not authenticated');
    }

    final insertData = {
      'tournament_id': tournamentId,
      'category_id': categoryId,
      'round': round,
      'round_name': roundName,
      'game_number': gameNumber,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'resource_id': resourceId,
      'scheduled_date': scheduledDate?.toIso8601String().split('T')[0],
      'scheduled_time': scheduledTime,
      'estimated_duration': estimatedDuration,
      'notes': notes,
      'is_published': isPublished,
      'created_by': user.id,
      'updated_by': user.id,
    };

    final data = await _supabaseClient
        .from('games')
        .insert(insertData)
        .select()
        .single();

    return GameModel.fromJson(data as Map<String, dynamic>);
  }

  /// Get all games for a tournament
  Future<List<GameModel>> getTournamentGames(String tournamentId) async {
    final data = await _supabaseClient
        .from('games')
        .select()
        .eq('tournament_id', tournamentId)
        .order('round', ascending: true)
        .order('game_number', ascending: true)
        .order('scheduled_date', ascending: true)
        .order('scheduled_time', ascending: true);

    return data.map((json) => GameModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get games for a specific category
  Future<List<GameModel>> getCategoryGames(String categoryId) async {
    final data = await _supabaseClient
        .from('games')
        .select()
        .eq('category_id', categoryId)
        .order('round', ascending: true)
        .order('game_number', ascending: true)
        .order('scheduled_date', ascending: true);

    return data.map((json) => GameModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get games for a specific team
  Future<List<GameModel>> getTeamGames(String teamId) async {
    final data = await _supabaseClient
        .from('games')
        .select()
        .or('team1_id.eq.$teamId,team2_id.eq.$teamId')
        .order('scheduled_date', ascending: true)
        .order('scheduled_time', ascending: true);

    return data.map((json) => GameModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get games scheduled for a specific resource
  Future<List<GameModel>> getResourceGames(String resourceId) async {
    final data = await _supabaseClient
        .from('games')
        .select()
        .eq('resource_id', resourceId)
        .order('scheduled_date', ascending: true)
        .order('scheduled_time', ascending: true);

    return data.map((json) => GameModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get games for a specific date range
  Future<List<GameModel>> getGamesByDateRange({
    required String tournamentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final data = await _supabaseClient
        .from('games')
        .select()
        .eq('tournament_id', tournamentId)
        .gte('scheduled_date', startDate.toIso8601String().split('T')[0])
        .lte('scheduled_date', endDate.toIso8601String().split('T')[0])
        .order('scheduled_date', ascending: true)
        .order('scheduled_time', ascending: true);

    return data.map((json) => GameModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get a single game by ID
  Future<GameModel?> getGame(String gameId) async {
    final data = await _supabaseClient
        .from('games')
        .select()
        .eq('id', gameId)
        .maybeSingle();

    if (data == null) return null;
    return GameModel.fromJson(data as Map<String, dynamic>);
  }

  /// Update game details
  Future<GameModel> updateGame({
    required String gameId,
    String? categoryId,
    int? round,
    String? roundName,
    int? gameNumber,
    String? team1Id,
    String? team2Id,
    String? resourceId,
    DateTime? scheduledDate,
    String? scheduledTime,
    int? estimatedDuration,
    GameStatus? status,
    String? notes,
    bool? isPublished,
    String? refereeNotes,
    String? streamUrl,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not authenticated');
    }

    final updateData = <String, dynamic>{
      'updated_by': user.id,
    };

    if (categoryId != null) updateData['category_id'] = categoryId;
    if (round != null) updateData['round'] = round;
    if (roundName != null) updateData['round_name'] = roundName;
    if (gameNumber != null) updateData['game_number'] = gameNumber;
    if (team1Id != null) updateData['team1_id'] = team1Id;
    if (team2Id != null) updateData['team2_id'] = team2Id;
    if (resourceId != null) updateData['resource_id'] = resourceId;
    if (scheduledDate != null) updateData['scheduled_date'] = scheduledDate.toIso8601String().split('T')[0];
    if (scheduledTime != null) updateData['scheduled_time'] = scheduledTime;
    if (estimatedDuration != null) updateData['estimated_duration'] = estimatedDuration;
    if (status != null) {
      // Convert enum to proper string value for database
      String statusValue;
      switch (status) {
        case GameStatus.scheduled:
          statusValue = 'scheduled';
          break;
        case GameStatus.inProgress:
          statusValue = 'in_progress';
          break;
        case GameStatus.completed:
          statusValue = 'completed';
          break;
        case GameStatus.cancelled:
          statusValue = 'cancelled';
          break;
        case GameStatus.postponed:
          statusValue = 'postponed';
          break;
        case GameStatus.forfeit:
          statusValue = 'forfeit';
          break;
      }
      updateData['status'] = statusValue;
    }
    if (notes != null) updateData['notes'] = notes;
    if (isPublished != null) updateData['is_published'] = isPublished;
    if (refereeNotes != null) updateData['referee_notes'] = refereeNotes;
    if (streamUrl != null) updateData['stream_url'] = streamUrl;

    final data = await _supabaseClient
        .from('games')
        .update(updateData)
        .eq('id', gameId)
        .select()
        .single();

    return GameModel.fromJson(data as Map<String, dynamic>);
  }

  /// Start a game
  Future<GameModel> startGame(String gameId) async {
    final updateData = {
      'status': 'in_progress', // Use the @JsonValue instead of .name
      'started_at': DateTime.now().toIso8601String(),
    };

    final data = await _supabaseClient
        .from('games')
        .update(updateData)
        .eq('id', gameId)
        .select()
        .single();

    return GameModel.fromJson(data as Map<String, dynamic>);
  }

  /// Complete a game with results
  Future<GameModel> completeGame({
    required String gameId,
    required int team1Score,
    required int team2Score,
    String? winnerId,
    String? refereeNotes,
  }) async {
    final updateData = {
      'status': 'completed', // Use the @JsonValue instead of .name
      'team1_score': team1Score,
      'team2_score': team2Score,
      'winner_id': winnerId,
      'completed_at': DateTime.now().toIso8601String(),
    };

    if (refereeNotes != null) {
      updateData['referee_notes'] = refereeNotes;
    }

    final data = await _supabaseClient
        .from('games')
        .update(updateData)
        .eq('id', gameId)
        .select()
        .single();

    return GameModel.fromJson(data as Map<String, dynamic>);
  }

  /// Cancel or postpone a game
  Future<GameModel> cancelGame(String gameId, {bool isPermanent = false}) async {
    final updateData = {
      'status': isPermanent ? 'cancelled' : 'postponed', // Use @JsonValue instead of .name
    };

    final data = await _supabaseClient
        .from('games')
        .update(updateData)
        .eq('id', gameId)
        .select()
        .single();

    return GameModel.fromJson(data as Map<String, dynamic>);
  }

  /// Delete a game
  Future<void> deleteGame(String gameId) async {
    await _supabaseClient
        .from('games')
        .delete()
        .eq('id', gameId);
  }

  /// Publish/unpublish games
  Future<void> publishGames(List<String> gameIds, bool isPublished) async {
    await _supabaseClient
        .from('games')
        .update({'is_published': isPublished})
        .inFilter('id', gameIds);
  }

  /// Get tournament statistics
  Future<Map<String, dynamic>> getTournamentGameStats(String tournamentId) async {
    final data = await _supabaseClient
        .from('games')
        .select('status')
        .eq('tournament_id', tournamentId);

    final Map<GameStatus, int> statusCounts = {};
    for (final item in data) {
      final status = GameStatus.values.firstWhere(
        (s) => s.name == item['status'],
        orElse: () => GameStatus.scheduled,
      );
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return {
      'total_games': data.length,
      'scheduled': statusCounts[GameStatus.scheduled] ?? 0,
      'in_progress': statusCounts[GameStatus.inProgress] ?? 0,
      'completed': statusCounts[GameStatus.completed] ?? 0,
      'cancelled': statusCounts[GameStatus.cancelled] ?? 0,
      'postponed': statusCounts[GameStatus.postponed] ?? 0,
      'forfeit': statusCounts[GameStatus.forfeit] ?? 0,
    };
  }

  /// Check for scheduling conflicts
  Future<List<GameModel>> getSchedulingConflicts({
    required String resourceId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? excludeGameId,
  }) async {
    var query = _supabaseClient
        .from('games')
        .select()
        .eq('resource_id', resourceId)
        .eq('scheduled_date', date.toIso8601String().split('T')[0])
        .gte('scheduled_time', startTime)
        .lte('scheduled_time', endTime);

    if (excludeGameId != null) {
      query = query.neq('id', excludeGameId);
    }

    final data = await query;
    return data.map((json) => GameModel.fromJson(json as Map<String, dynamic>)).toList();
  }
} 