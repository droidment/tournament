import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/game_model.dart';
import '../../../../core/models/tournament_standings_model.dart';
import '../../../../core/models/team_model.dart';
import '../repositories/game_repository.dart';
import '../models/tournament_model.dart';
import 'tournament_standings_service.dart';

class LiveScoreService {
  final SupabaseClient _supabaseClient;
  final GameRepository _gameRepository;
  
  // Stream controllers for real-time updates
  final StreamController<List<GameModel>> _gamesController = StreamController<List<GameModel>>.broadcast();
  final StreamController<TournamentStandingsModel> _standingsController = StreamController<TournamentStandingsModel>.broadcast();
  final StreamController<GameModel> _gameUpdateController = StreamController<GameModel>.broadcast();
  
  // Subscription for database changes
  RealtimeChannel? _gameSubscription;
  RealtimeChannel? _scoreSubscription;
  
  // Cache for performance
  final Map<String, List<GameModel>> _tournamentGamesCache = {};
  final Map<String, TournamentStandingsModel> _standingsCache = {};
  Timer? _cacheRefreshTimer;

  LiveScoreService({SupabaseClient? supabaseClient, GameRepository? gameRepository})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client,
        _gameRepository = gameRepository ?? GameRepository() {
    _initializeRealtimeSubscriptions();
    _startCacheRefreshTimer();
  }

  // Getters for streams
  Stream<List<GameModel>> get gamesStream => _gamesController.stream;
  Stream<TournamentStandingsModel> get standingsStream => _standingsController.stream;
  Stream<GameModel> get gameUpdateStream => _gameUpdateController.stream;

  /// Initialize real-time subscriptions for live updates
  void _initializeRealtimeSubscriptions() {
    // Subscribe to games table changes
    _gameSubscription = _supabaseClient
        .channel('games_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'games',
          callback: _handleGameUpdate,
        )
        .subscribe();

    print('🔴 Live Score Service: Real-time subscriptions initialized');
  }

  /// Start periodic cache refresh timer
  void _startCacheRefreshTimer() {
    _cacheRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _refreshAllCaches();
    });
  }

  /// Handle real-time game updates from database
  void _handleGameUpdate(PostgresChangePayload payload) async {
    print('🔄 Live update received: ${payload.eventType} for table ${payload.table}');
    
    try {
      final gameData = payload.newRecord;
      if (gameData != null) {
        final game = GameModel.fromJson(gameData);
        
        // Update cache
        final tournamentId = game.tournamentId;
        if (_tournamentGamesCache.containsKey(tournamentId)) {
          final games = _tournamentGamesCache[tournamentId]!;
          final index = games.indexWhere((g) => g.id == game.id);
          
          if (index >= 0) {
            games[index] = game;
          } else if (payload.eventType == PostgresChangeEvent.insert) {
            games.add(game);
          }
          
          // Broadcast updated games list
          _gamesController.add(List.from(games));
        }
        
        // Broadcast individual game update
        _gameUpdateController.add(game);
        
        // Update standings if game is completed
        if (game.status == GameStatus.completed && game.hasResults) {
          await _updateTournamentStandings(tournamentId);
        }
        
        print('✅ Live update processed for game ${game.id}');
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        // Handle game deletion
        final oldRecord = payload.oldRecord;
        if (oldRecord != null) {
          final tournamentId = oldRecord['tournament_id'] as String;
          final gameId = oldRecord['id'] as String;
          
          if (_tournamentGamesCache.containsKey(tournamentId)) {
            final games = _tournamentGamesCache[tournamentId]!;
            games.removeWhere((g) => g.id == gameId);
            _gamesController.add(List.from(games));
          }
        }
      }
    } catch (e) {
      print('❌ Error processing live update: $e');
    }
  }

  /// Update game score in real-time
  Future<GameModel> updateGameScore({
    required String gameId,
    required int team1Score,
    required int team2Score,
    GameStatus? status,
    String? winnerId,
    String? notes,
  }) async {
    try {
      print('🎯 Updating game score: $gameId - $team1Score:$team2Score');

      // Determine winner if not provided
      String? finalWinnerId = winnerId;
      if (finalWinnerId == null && team1Score != team2Score) {
        final game = await _gameRepository.getGame(gameId);
        if (game != null && game.hasTeams) {
          finalWinnerId = team1Score > team2Score ? game.team1Id : game.team2Id;
        }
      }

      // Determine status if not provided
      GameStatus finalStatus = status ?? GameStatus.inProgress;
      if (status == null) {
        // Auto-determine status based on context
        if (team1Score > 0 || team2Score > 0) {
          finalStatus = GameStatus.inProgress;
        }
      }

      // Update game in database - check if this is a completion or just score update
      final GameModel updatedGame;
      if (finalStatus == GameStatus.completed) {
        updatedGame = await _gameRepository.completeGame(
          gameId: gameId,
          team1Score: team1Score,
          team2Score: team2Score,
          winnerId: finalWinnerId,
          refereeNotes: notes,
        );
      } else {
        // For in-progress games, we'll need to use the existing updateGame with status change
        // and handle scores separately through database update
        updatedGame = await _gameRepository.updateGame(
          gameId: gameId,
          status: finalStatus,
          notes: notes,
        );
        
        // Update scores directly in database for in-progress games
        await _supabaseClient
            .from('games')
            .update({
              'team1_score': team1Score,
              'team2_score': team2Score,
              'winner_id': finalWinnerId,
            })
            .eq('id', gameId);
      }

      print('✅ Game score updated successfully');
      return updatedGame;
    } catch (e) {
      print('❌ Error updating game score: $e');
      rethrow;
    }
  }

  /// Complete a game with final scores
  Future<GameModel> completeGame({
    required String gameId,
    required int team1Score,
    required int team2Score,
    String? winnerId,
    String? notes,
    String? refereeNotes,
  }) async {
    try {
      print('🏁 Completing game: $gameId - $team1Score:$team2Score');

      final game = await _gameRepository.getGame(gameId);
      if (game == null) {
        throw Exception('Game not found');
      }

      // Determine winner
      String? finalWinnerId = winnerId;
      if (finalWinnerId == null && game.hasTeams) {
        if (team1Score > team2Score) {
          finalWinnerId = game.team1Id;
        } else if (team2Score > team1Score) {
          finalWinnerId = game.team2Id;
        }
        // If scores are equal, no winner (draw)
      }

      // Update game as completed using the completeGame method
      final updatedGame = await _gameRepository.completeGame(
        gameId: gameId,
        team1Score: team1Score,
        team2Score: team2Score,
        winnerId: finalWinnerId,
        refereeNotes: refereeNotes ?? notes,
      );

      // Update tournament standings
      await _updateTournamentStandings(game.tournamentId);

      print('✅ Game completed successfully');
      return updatedGame;
    } catch (e) {
      print('❌ Error completing game: $e');
      rethrow;
    }
  }

  /// Start a game
  Future<GameModel> startGame({
    required String gameId,
    String? notes,
  }) async {
    try {
      print('▶️ Starting game: $gameId');

      // Use the dedicated startGame method or updateGame with status
      final updatedGame = await _gameRepository.startGame(gameId);
      
      // Update notes if provided
      if (notes != null) {
        await _gameRepository.updateGame(
          gameId: gameId,
          notes: notes,
        );
      }

      print('✅ Game started successfully');
      return updatedGame;
    } catch (e) {
      print('❌ Error starting game: $e');
      rethrow;
    }
  }

  /// Cancel/postpone a game
  Future<GameModel> cancelGame({
    required String gameId,
    required GameStatus status, // cancelled or postponed
    String? notes,
  }) async {
    try {
      print('⏸️ Cancelling/postponing game: $gameId');

      if (status != GameStatus.cancelled && status != GameStatus.postponed) {
        throw ArgumentError('Status must be cancelled or postponed');
      }

      // Use the dedicated cancelGame method
      final updatedGame = await _gameRepository.cancelGame(
        gameId, 
        isPermanent: status == GameStatus.cancelled,
      );
      
      // Update notes if provided
      if (notes != null) {
        await _gameRepository.updateGame(
          gameId: gameId,
          notes: notes,
        );
      }

      print('✅ Game ${status.name} successfully');
      return updatedGame;
    } catch (e) {
      print('❌ Error cancelling/postponing game: $e');
      rethrow;
    }
  }

  /// Get live games for a tournament
  Future<List<GameModel>> getTournamentGames(String tournamentId, {bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _tournamentGamesCache.containsKey(tournamentId)) {
      return _tournamentGamesCache[tournamentId]!;
    }

    try {
      print('📋 Fetching tournament games: $tournamentId');

      final games = await _gameRepository.getTournamentGames(tournamentId);
      
      // Update cache
      _tournamentGamesCache[tournamentId] = games;
      
      // Broadcast to stream
      _gamesController.add(games);

      print('✅ Fetched ${games.length} games for tournament');
      return games;
    } catch (e) {
      print('❌ Error fetching tournament games: $e');
      rethrow;
    }
  }

  /// Get live standings for a tournament
  Future<TournamentStandingsModel> getTournamentStandings({
    required String tournamentId,
    required TournamentFormat format,
    required List<TeamModel> teams,
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not forcing refresh
    if (!forceRefresh && _standingsCache.containsKey(tournamentId)) {
      return _standingsCache[tournamentId]!;
    }

    try {
      print('📊 Calculating tournament standings: $tournamentId');

      final games = await getTournamentGames(tournamentId, forceRefresh: forceRefresh);
      
      final standings = TournamentStandingsService.calculateStandings(
        tournamentId: tournamentId,
        format: format,
        games: games,
        teams: teams,
      );

      // Update cache
      _standingsCache[tournamentId] = standings;
      
      // Broadcast to stream
      _standingsController.add(standings);

      print('✅ Standings calculated for ${teams.length} teams');
      return standings;
    } catch (e) {
      print('❌ Error calculating standings: $e');
      rethrow;
    }
  }

  /// Update tournament standings after a game completion
  Future<void> _updateTournamentStandings(String tournamentId) async {
    try {
      // This would need tournament format and teams data
      // For now, just clear the cache to force refresh
      _standingsCache.remove(tournamentId);
      print('🔄 Standings cache cleared for tournament: $tournamentId');
    } catch (e) {
      print('❌ Error updating standings: $e');
    }
  }

  /// Get live score for a specific game
  Future<GameModel?> getGameScore(String gameId) async {
    try {
      return await _gameRepository.getGame(gameId);
    } catch (e) {
      print('❌ Error fetching game score: $e');
      return null;
    }
  }

  /// Subscribe to live updates for a tournament
  void subscribeToTournament(String tournamentId) {
    print('🔔 Subscribing to tournament: $tournamentId');
    // Tournament-specific subscription could be added here
    // For now, the general subscription handles all tournaments
  }

  /// Unsubscribe from tournament updates  
  void unsubscribeFromTournament(String tournamentId) {
    print('🔕 Unsubscribing from tournament: $tournamentId');
    // Clear tournament cache
    _tournamentGamesCache.remove(tournamentId);
    _standingsCache.remove(tournamentId);
  }

  /// Refresh all cached data
  Future<void> _refreshAllCaches() async {
    print('🔄 Refreshing all caches...');
    
    // Refresh games cache
    for (final tournamentId in _tournamentGamesCache.keys.toList()) {
      try {
        await getTournamentGames(tournamentId, forceRefresh: true);
      } catch (e) {
        print('❌ Error refreshing games cache for $tournamentId: $e');
      }
    }

    print('✅ Cache refresh completed');
  }

  /// Get tournament games with live status
  Stream<List<GameModel>> watchTournamentGames(String tournamentId) async* {
    // Emit initial data
    try {
      final games = await getTournamentGames(tournamentId);
      yield games;
    } catch (e) {
      print('❌ Error getting initial games: $e');
    }

    // Listen for live updates
    await for (final games in _gamesController.stream) {
      // Filter for this tournament if the stream contains multiple tournaments
      if (games.isNotEmpty && games.first.tournamentId == tournamentId) {
        yield games;
      }
    }
  }

  /// Get tournament standings with live updates
  Stream<TournamentStandingsModel> watchTournamentStandings({
    required String tournamentId,
    required TournamentFormat format,
    required List<TeamModel> teams,
  }) async* {
    // Emit initial data
    try {
      final standings = await getTournamentStandings(
        tournamentId: tournamentId,
        format: format,
        teams: teams,
      );
      yield standings;
    } catch (e) {
      print('❌ Error getting initial standings: $e');
    }

    // Listen for live updates
    await for (final standings in _standingsController.stream) {
      if (standings.tournamentId == tournamentId) {
        yield standings;
      }
    }
  }

  /// Clean up resources
  void dispose() {
    print('🧹 Disposing Live Score Service');
    
    _gameSubscription?.unsubscribe();
    _scoreSubscription?.unsubscribe();
    _cacheRefreshTimer?.cancel();
    
    _gamesController.close();
    _standingsController.close();
    _gameUpdateController.close();
    
    _tournamentGamesCache.clear();
    _standingsCache.clear();
  }
} 