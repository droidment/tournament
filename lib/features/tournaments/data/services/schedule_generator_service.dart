import 'package:flutter/material.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/tournament_resource_model.dart';
import '../../../../core/models/resource_availability_model.dart';
import '../../../../core/models/game_model.dart';
import '../repositories/game_repository.dart';
import '../repositories/resource_availability_repository.dart';

class ScheduleGeneratorService {
  final GameRepository _gameRepository = GameRepository();
  final ResourceAvailabilityRepository _availabilityRepository = ResourceAvailabilityRepository();

  /// Generate round robin schedule for all teams
  Future<List<GameModel>> generateRoundRobinSchedule({
    required String tournamentId,
    required List<TeamModel> teams,
    required List<TournamentResourceModel> resources,
    required DateTime startDate,
    required DateTime endDate,
    required int gameDurationMinutes,
    required int timeBetweenGamesMinutes,
    String? categoryId,
  }) async {
    print('🎯 DEBUG: Starting round robin schedule generation');
    print('📊 Teams: ${teams.length}');
    print('🏟️ Resources: ${resources.length}');
    print('📅 Date range: $startDate to $endDate');
    print('⏱️ Game duration: ${gameDurationMinutes}min, Between games: ${timeBetweenGamesMinutes}min');

    if (teams.length < 2) {
      print('❌ ERROR: Need at least 2 teams for round robin');
      throw Exception('Need at least 2 teams for round robin tournament');
    }

    // Generate all possible matchups
    final matchups = _generateRoundRobinMatchups(teams);
    print('🔀 Generated ${matchups.length} matchups');
    for (int i = 0; i < matchups.length; i++) {
      final matchup = matchups[i];
      print('   Game ${i + 1}: ${matchup.team1.name} vs ${matchup.team2.name}');
    }

    // Get available time slots for all resources
    final timeSlots = await _getAvailableTimeSlots(
      resources: resources,
      startDate: startDate,
      endDate: endDate,
      gameDurationMinutes: gameDurationMinutes,
      breakBetweenGames: timeBetweenGamesMinutes,
    );
    print('📋 Total available time slots: ${timeSlots.length}');

    // Calculate maximum simultaneous games
    final maxSimultaneousGames = resources.length; // Each resource can host 1 game at a time
    print('🎮 Maximum simultaneous games: $maxSimultaneousGames');

    // Check if we have enough time slots
    final requiredTimeSlots = (matchups.length / maxSimultaneousGames).ceil();
    print('🧮 Required time slots: $requiredTimeSlots (${matchups.length} games ÷ $maxSimultaneousGames)');
    print('🔍 Available time slots: ${timeSlots.length}');

    if (timeSlots.length < requiredTimeSlots) {
      print('❌ ERROR: Not enough time slots!');
      print('   Need: $requiredTimeSlots');
      print('   Have: ${timeSlots.length}');
      print('📋 Available time slots details:');
      for (int i = 0; i < timeSlots.length; i++) {
        final slot = timeSlots[i];
        print('     ${i + 1}. ${slot.toString()}');
      }
      throw Exception(
        'Not enough time slots for all games. '
        'Need $requiredTimeSlots time slots but only found ${timeSlots.length}. '
        'Consider extending the date range, adding more resources, or reducing game duration.'
      );
    }

    print('✅ Sufficient time slots available, proceeding with scheduling...');

    // Schedule games optimally
    final games = _scheduleGamesOptimally(
      matchups,
      timeSlots,
      resources,
      tournamentId,
      categoryId,
      gameDurationMinutes,
    );

    print('🎉 Successfully scheduled ${games.length} games');

    // Create games in database
    print('💾 Creating games in database...');
    final createdGames = <GameModel>[];
    for (int i = 0; i < games.length; i++) {
      final game = games[i];
      print('   Creating game ${i + 1}/${games.length}: ${game.displayName}');
      try {
        final createdGame = await _gameRepository.createGame(
          tournamentId: game.tournamentId,
          categoryId: game.categoryId,
          round: game.round,
          roundName: game.roundName ?? 'Round Robin',
          gameNumber: game.gameNumber,
          team1Id: game.team1Id,
          team2Id: game.team2Id,
          resourceId: game.resourceId,
          scheduledDate: game.scheduledDate,
          scheduledTime: game.scheduledTime,
          estimatedDuration: game.estimatedDuration,
          notes: game.notes,
          isPublished: true,
        );
        createdGames.add(createdGame);
        print('     ✅ Created successfully');
      } catch (e) {
        print('     ❌ Error creating game: $e');
        throw Exception('Failed to create game ${game.displayName}: $e');
      }
    }

    print('🎯 Schedule generation completed successfully!');
    return createdGames;
  }

  /// Generate all possible team combinations for round robin
  List<TeamMatchup> _generateRoundRobinMatchups(List<TeamModel> teams) {
    final List<TeamMatchup> matchups = [];
    
    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        matchups.add(TeamMatchup(
          team1: teams[i],
          team2: teams[j],
        ));
      }
    }
    
    return matchups;
  }

  /// Get all available time slots across resources and dates
  Future<List<TimeSlot>> _getAvailableTimeSlots({
    required List<TournamentResourceModel> resources,
    required DateTime startDate,
    required DateTime endDate,
    required int gameDurationMinutes,
    required int breakBetweenGames,
  }) async {
    final List<TimeSlot> allSlots = [];
    
    for (final resource in resources) {
      final resourceSlots = await _getResourceTimeSlots(
        resource: resource,
        startDate: startDate,
        endDate: endDate,
        gameDurationMinutes: gameDurationMinutes,
        breakBetweenGames: breakBetweenGames,
      );
      allSlots.addAll(resourceSlots);
    }
    
    // Sort by date and time for optimal scheduling
    allSlots.sort((a, b) {
      final dateComparison = a.date.compareTo(b.date);
      if (dateComparison != 0) return dateComparison;
      return a.startTime.compareTo(b.startTime);
    });
    
    return allSlots;
  }

  /// Get available time slots for a specific resource
  Future<List<TimeSlot>> _getResourceTimeSlots({
    required TournamentResourceModel resource,
    required DateTime startDate,
    required DateTime endDate,
    required int gameDurationMinutes,
    required int breakBetweenGames,
  }) async {
    final List<TimeSlot> slots = [];
    
    print('🔍 Checking availability for resource: ${resource.name} (${resource.id})');
    
    // Get resource availability
    final availabilities = await _availabilityRepository.getResourceAvailability(resource.id);
    print('📋 Found ${availabilities.length} availability records for ${resource.name}');
    
    if (availabilities.isEmpty) {
      print('⚠️ No availability defined for ${resource.name}! Creating default availability...');
      // Create default availability: Monday to Friday, 5 AM to 11 PM
      final defaultAvailabilities = <ResourceAvailabilityModel>[];
      for (int day = 1; day <= 5; day++) { // Monday to Friday
        defaultAvailabilities.add(ResourceAvailabilityModel(
          id: 'default_$day',
          resourceId: resource.id,
          dayOfWeek: day,
          startTime: '05:00',
          endTime: '23:00',
          isAvailable: true,
          createdAt: DateTime.now(),
        ));
      }
      
      // Filter availabilities for the date range
      final filteredAvailabilities = defaultAvailabilities.where((avail) {
        if (avail.specificDate != null) {
          return !avail.specificDate!.isBefore(startDate) && 
                 !avail.specificDate!.isAfter(endDate);
        }
        return true; // Include recurring availabilities
      }).toList();
      
      print('🔧 Using default availability: Monday-Friday 5:00-23:00 for ${resource.name}');
      
      // Get existing games to avoid conflicts
      final existingGames = await _gameRepository.getResourceGames(resource.id);
      
      // Generate time slots for each day
      for (DateTime date = startDate; 
           date.isBefore(endDate.add(const Duration(days: 1))); 
           date = date.add(const Duration(days: 1))) {
        
        final daySlots = _generateDayTimeSlots(
          resource: resource,
          date: date,
          availabilities: filteredAvailabilities,
          existingGames: existingGames,
          gameDurationMinutes: gameDurationMinutes,
          breakBetweenGames: breakBetweenGames,
        );
        
        print('📅 ${date.day}/${date.month}/${date.year} (${_getDayName(date.weekday)}): ${daySlots.length} slots for ${resource.name}');
        slots.addAll(daySlots);
      }
    } else {
      print('✅ Using defined availability for ${resource.name}:');
      for (final avail in availabilities) {
        if (avail.isRecurring) {
          print('   - ${avail.fullDayName}: ${avail.timeRange} (recurring)');
        } else {
          print('   - ${avail.displayDate}: ${avail.timeRange} (specific date)');
        }
      }
      
      // Filter availabilities for the date range
      final filteredAvailabilities = availabilities.where((avail) {
        if (avail.specificDate != null) {
          return !avail.specificDate!.isBefore(startDate) && 
                 !avail.specificDate!.isAfter(endDate);
        }
        return true; // Include recurring availabilities
      }).toList();
      
      // Get existing games to avoid conflicts
      final existingGames = await _gameRepository.getResourceGames(resource.id);
      
      // Generate time slots for each day
      for (DateTime date = startDate; 
           date.isBefore(endDate.add(const Duration(days: 1))); 
           date = date.add(const Duration(days: 1))) {
        
        final daySlots = _generateDayTimeSlots(
          resource: resource,
          date: date,
          availabilities: filteredAvailabilities,
          existingGames: existingGames,
          gameDurationMinutes: gameDurationMinutes,
          breakBetweenGames: breakBetweenGames,
        );
        
        print('📅 ${date.day}/${date.month}/${date.year} (${_getDayName(date.weekday)}): ${daySlots.length} slots for ${resource.name}');
        slots.addAll(daySlots);
      }
    }
    
    print('🎯 Total slots generated for ${resource.name}: ${slots.length}');
    return slots;
  }

  /// Generate time slots for a specific day
  List<TimeSlot> _generateDayTimeSlots({
    required TournamentResourceModel resource,
    required DateTime date,
    required List<ResourceAvailabilityModel> availabilities,
    required List<GameModel> existingGames,
    required int gameDurationMinutes,
    required int breakBetweenGames,
  }) {
    final List<TimeSlot> slots = [];
    final dayOfWeek = date.weekday % 7; // Convert to 0-6 format
    
    print('  🔍 Processing ${_getDayName(date.weekday)} ${date.day}/${date.month}/${date.year} (dayOfWeek: $dayOfWeek)');
    
    // Find applicable availability for this day
    final dayAvailabilities = availabilities.where((avail) {
      if (avail.isAvailable == false) return false;
      
      if (avail.isRecurring) {
        return avail.dayOfWeek == dayOfWeek;
      } else {
        return avail.specificDate != null && 
               _isSameDate(avail.specificDate!, date);
      }
    }).toList();
    
    print('  📋 Found ${dayAvailabilities.length} applicable availability windows for this day');
    for (final avail in dayAvailabilities) {
      print('    - ${avail.timeRange} (${avail.isRecurring ? 'recurring' : 'specific'})');
    }
    
    // Find existing games on this day
    final dayGames = existingGames.where((game) {
      return game.scheduledDate != null && 
             _isSameDate(game.scheduledDate!, date);
    }).toList();
    
    print('  🎮 Found ${dayGames.length} existing games on this day');
    
    // Generate slots for each availability window
    for (final availability in dayAvailabilities) {
      final windowSlots = _generateAvailabilitySlots(
        resource: resource,
        date: date,
        availability: availability,
        existingGames: dayGames,
        gameDurationMinutes: gameDurationMinutes,
        breakBetweenGames: breakBetweenGames,
      );
      
      print('    ⏰ Window ${availability.timeRange}: generated ${windowSlots.length} slots');
      slots.addAll(windowSlots);
    }
    
    print('  📊 Total slots for this day: ${slots.length}');
    return slots;
  }

  /// Generate time slots within an availability window
  List<TimeSlot> _generateAvailabilitySlots({
    required TournamentResourceModel resource,
    required DateTime date,
    required ResourceAvailabilityModel availability,
    required List<GameModel> existingGames,
    required int gameDurationMinutes,
    required int breakBetweenGames,
  }) {
    final List<TimeSlot> slots = [];
    
    final startTime = _parseTime(availability.startTime);
    final endTime = _parseTime(availability.endTime);
    final totalSlotMinutes = gameDurationMinutes + breakBetweenGames;
    
    DateTime currentSlotStart = DateTime(
      date.year, 
      date.month, 
      date.day, 
      startTime.hour, 
      startTime.minute
    );
    
    final windowEnd = DateTime(
      date.year, 
      date.month, 
      date.day, 
      endTime.hour, 
      endTime.minute
    );
    
    while (currentSlotStart.add(Duration(minutes: gameDurationMinutes)).isBefore(windowEnd) ||
           currentSlotStart.add(Duration(minutes: gameDurationMinutes)).isAtSameMomentAs(windowEnd)) {
      
      final slotEnd = currentSlotStart.add(Duration(minutes: gameDurationMinutes));
      
      // Check if this slot conflicts with existing games
      bool hasConflict = false;
      for (final game in existingGames) {
        if (game.scheduledTime != null) {
          final gameStart = DateTime(
            date.year,
            date.month,
            date.day,
            _parseTime(game.scheduledTime!).hour,
            _parseTime(game.scheduledTime!).minute,
          );
          final gameEnd = gameStart.add(Duration(minutes: game.estimatedDuration));
          
          // Check for overlap
          if (currentSlotStart.isBefore(gameEnd) && slotEnd.isAfter(gameStart)) {
            hasConflict = true;
            break;
          }
        }
      }
      
      if (!hasConflict) {
        slots.add(TimeSlot(
          resourceId: resource.id,
          resourceName: resource.name,
          date: date,
          startTime: _formatTime(TimeOfDay.fromDateTime(currentSlotStart)),
          endTime: _formatTime(TimeOfDay.fromDateTime(slotEnd)),
        ));
      }
      
      currentSlotStart = currentSlotStart.add(Duration(minutes: totalSlotMinutes));
    }
    
    return slots;
  }

  // Helper methods
  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  int _calculateRound(int gameIndex, int teamCount) {
    // For round robin, we can distribute games across rounds
    final gamesPerRound = (teamCount / 2).ceil();
    return (gameIndex / gamesPerRound).floor() + 1;
  }

  String _getRoundName(int gameIndex, int teamCount, int totalGames) {
    // For round robin, all games should be called "Round Robin"
    return 'Round Robin';
  }

  /// Calculate total number of games for round robin
  static int calculateRoundRobinGames(int teamCount) {
    if (teamCount < 2) return 0;
    return (teamCount * (teamCount - 1)) ~/ 2;
  }

  /// Estimate tournament duration
  static Duration estimateTournamentDuration({
    required int totalGames,
    required int resourceCount,
    required int gameDurationMinutes,
    required int breakBetweenGames,
  }) {
    if (resourceCount == 0) return Duration.zero;
    
    final totalGameTime = totalGames * gameDurationMinutes;
    final totalBreakTime = totalGames * breakBetweenGames;
    final parallelFactor = resourceCount;
    
    final totalMinutes = ((totalGameTime + totalBreakTime) / parallelFactor).ceil();
    return Duration(minutes: totalMinutes);
  }

  /// Schedule games optimally across available time slots
  List<GameModel> _scheduleGamesOptimally(
    List<TeamMatchup> matchups,
    List<TimeSlot> timeSlots,
    List<TournamentResourceModel> resources,
    String tournamentId,
    String? categoryId,
    int gameDurationMinutes,
  ) {
    print('🔧 Starting optimal game scheduling with team conflict prevention...');
    final List<GameModel> scheduledGames = [];

    for (int i = 0; i < matchups.length; i++) {
      final matchup = matchups[i];
      
      print('   📋 Finding slot for Game ${i + 1}: ${matchup.team1.name} vs ${matchup.team2.name}');
      
      // Find the first available slot where neither team has a conflict
      TimeSlot? availableSlot;
      int slotIndex = -1;
      
      for (int j = 0; j < timeSlots.length; j++) {
        final slot = timeSlots[j];
        
        // Check if this slot creates a team conflict
        bool hasTeamConflict = false;
        
        for (final existingGame in scheduledGames) {
          // Check if the slot overlaps with any existing game
          if (_sameSlotTime(slot, existingGame)) {
            // Check if either team in this matchup is already playing
            if (existingGame.team1Id == matchup.team1.id || 
                existingGame.team1Id == matchup.team2.id ||
                existingGame.team2Id == matchup.team1.id || 
                existingGame.team2Id == matchup.team2.id) {
              hasTeamConflict = true;
              print('     ❌ Slot conflict: ${slot.resourceName} ${slot.startTime} - team already playing');
              break;
            }
          }
        }
        
        if (!hasTeamConflict) {
          availableSlot = slot;
          slotIndex = j;
          print('     ✅ Found available slot: ${slot.resourceName} ${slot.startTime}');
          break;
        }
      }
      
      if (availableSlot == null) {
        print('     ❌ No available slot found for ${matchup.team1.name} vs ${matchup.team2.name}');
        continue;
      }

      print('   ✅ Scheduling Game ${i + 1}: ${matchup.team1.name} vs ${matchup.team2.name}');
      print('     📍 Resource: ${availableSlot.resourceName}');
      print('     📅 Date: ${availableSlot.date.day}/${availableSlot.date.month}/${availableSlot.date.year}');
      print('     ⏰ Time: ${availableSlot.startTime}');

      final game = GameModel(
        id: '', // Will be set by repository
        tournamentId: tournamentId,
        categoryId: categoryId,
        round: 1, // All round robin games are in round 1
        roundName: 'Round Robin',
        gameNumber: i + 1,
        team1Id: matchup.team1.id,
        team2Id: matchup.team2.id,
        resourceId: availableSlot.resourceId,
        scheduledDate: availableSlot.date,
        scheduledTime: availableSlot.startTime,
        estimatedDuration: gameDurationMinutes,
        status: GameStatus.scheduled,
        notes: 'Auto-generated Round Robin game: ${matchup.team1.name} vs ${matchup.team2.name} at ${availableSlot.resourceName}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      scheduledGames.add(game);
      
      // Remove the used slot from available slots to prevent double-booking
      timeSlots.removeAt(slotIndex);
    }

    print('📊 Successfully scheduled ${scheduledGames.length} out of ${matchups.length} games');
    
    if (scheduledGames.length < matchups.length) {
      final missed = matchups.length - scheduledGames.length;
      print('⚠️ WARNING: Could not schedule $missed games due to team conflicts or insufficient slots');
    }
    
    return scheduledGames;
  }

  /// Check if a time slot matches an existing game's time and date
  bool _sameSlotTime(TimeSlot slot, GameModel game) {
    if (game.scheduledDate == null || game.scheduledTime == null) return false;
    
    return _isSameDate(slot.date, game.scheduledDate!) && 
           slot.startTime == game.scheduledTime;
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Day $day';
    }
  }
}

// Supporting classes
class TeamMatchup {
  final TeamModel team1;
  final TeamModel team2;

  TeamMatchup({
    required this.team1,
    required this.team2,
  });

  @override
  String toString() => '${team1.name} vs ${team2.name}';
}

class TimeSlot {
  final String resourceId;
  final String resourceName;
  final DateTime date;
  final String startTime;
  final String endTime;

  TimeSlot({
    required this.resourceId,
    required this.resourceName,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  String toString() => 
      '$resourceName on ${date.day}/${date.month}/${date.year} at $startTime-$endTime';
} 