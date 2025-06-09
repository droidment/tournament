import 'dart:math';
import 'package:teamapp3/features/tournaments/data/models/tournament_group_model.dart';
import 'package:teamapp3/features/tournaments/data/models/tournament_tier_model.dart';
import 'package:teamapp3/core/models/team_model.dart';
import 'package:teamapp3/core/models/game_model.dart';
import 'package:teamapp3/core/models/tournament_bracket_model.dart';
import 'package:uuid/uuid.dart';

class TieredTournamentService {
  static const _uuid = Uuid();

  /// Configurable scoring system
  static const int defaultWinPoints = 2;
  static const int defaultTiePoints = 1;
  static const int defaultLossPoints = 0;

  /// Calculate optimal group structure for given number of teams
  static TieredTournamentStructure calculateOptimalStructure(int totalTeams) {
    // Find the best group size (prefer 4 teams per group)
    int groupSize = 4;
    int numGroups = totalTeams ~/ groupSize;
    int usableTeams = numGroups * groupSize;
    int eliminatedTeams = totalTeams - usableTeams;

    // If we eliminate too many teams, try group size of 3
    if (eliminatedTeams > totalTeams * 0.2) {
      groupSize = 3;
      numGroups = totalTeams ~/ groupSize;
      usableTeams = numGroups * groupSize;
      eliminatedTeams = totalTeams - usableTeams;
    }

    // Calculate tier distribution
    final tierDistribution = _calculateTierDistribution(numGroups, groupSize);

    return TieredTournamentStructure(
      totalTeams: totalTeams,
      usableTeams: usableTeams,
      eliminatedTeams: eliminatedTeams,
      numGroups: numGroups,
      groupSize: groupSize,
      proTierTeams: tierDistribution.proTierTeams,
      intermediateTierTeams: tierDistribution.intermediateTierTeams,
      noviceTierTeams: tierDistribution.noviceTierTeams,
    );
  }

  /// Generate groups with snake-draft seeding
  static List<TournamentGroupModel> generateGroups({
    required String tournamentId,
    required List<TeamModel> teams,
    required TieredTournamentStructure structure,
  }) {
    // Sort teams by seed (assuming teams are already seeded)
    final sortedTeams = List<TeamModel>.from(teams)
      ..sort((a, b) => a.name.compareTo(b.name)); // Placeholder sort

    // Take only the usable teams
    final usableTeams = sortedTeams.take(structure.usableTeams).toList();

    // Create groups
    final groups = <TournamentGroupModel>[];
    for (int i = 0; i < structure.numGroups; i++) {
      groups.add(TournamentGroupModel(
        id: _uuid.v4(),
        tournamentId: tournamentId,
        groupName: 'Group ${String.fromCharCode(65 + i)}', // A, B, C, D...
        groupNumber: i + 1,
        teamIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    // Snake draft distribution
    _distributeTeamsSnakeDraft(usableTeams, groups);

    print('🏗️ Generated ${groups.length} groups with snake-draft seeding');
    for (final group in groups) {
      print('   ${group.groupName}: ${group.teamIds.length} teams');
    }

    return groups;
  }

  /// Generate round-robin games for all groups with optimized court utilization
  static List<GameModel> generateGroupStageGames({
    required String tournamentId,
    required List<TournamentGroupModel> groups,
    required List<String> resourceIds,
    required DateTime tournamentStart,
    required int gameDurationMinutes,
    required int timeBetweenGamesMinutes,
  }) {
    final games = <GameModel>[];
    var gameNumber = 1;

    // Assign each group to a specific court for optimal court utilization
    final groupCourtAssignments = <String, String>{};
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (group.teamIds.length >= 2) {
        // Assign group to a court (cycle through available courts)
        final courtIndex = i % resourceIds.length;
        groupCourtAssignments[group.id] = resourceIds[courtIndex];
        
        print('📋 ${group.groupName} → ${_getCourtName(resourceIds[courtIndex], resourceIds)}');
      }
    }

    // Generate games for each group with their assigned court
    final groupGamesMap = <String, List<GameModel>>{};
    
    for (final group in groups) {
      if (group.teamIds.length < 2) continue;
      
      final assignedCourt = groupCourtAssignments[group.id];
      if (assignedCourt == null) continue;

      // Generate round-robin matchups for this group on its assigned court
      final groupGames = _generateRoundRobinForGroupOptimized(
        tournamentId: tournamentId,
        group: group,
        assignedResourceId: assignedCourt,
        startTime: tournamentStart,
        gameDurationMinutes: gameDurationMinutes,
        timeBetweenGamesMinutes: timeBetweenGamesMinutes,
        startingGameNumber: gameNumber,
      );

      groupGamesMap[group.id] = groupGames;
      gameNumber += groupGames.length;
    }

    // Merge all group games while maintaining court assignments
    for (final group in groups) {
      if (groupGamesMap.containsKey(group.id)) {
        games.addAll(groupGamesMap[group.id]!);
      }
    }

    // Sort games by scheduled time for better organization
    games.sort((a, b) {
      if (a.scheduledDate == null || b.scheduledDate == null) return 0;
      if (a.scheduledTime == null || b.scheduledTime == null) return 0;
      
      final aDateTime = _parseGameDateTime(a.scheduledDate!, a.scheduledTime!);
      final bDateTime = _parseGameDateTime(b.scheduledDate!, b.scheduledTime!);
      return aDateTime.compareTo(bDateTime);
    });

    print('🏟️ Court assignments:');
    groupCourtAssignments.forEach((groupId, courtId) {
      final group = groups.firstWhere((g) => g.id == groupId);
      final courtName = _getCourtName(courtId, resourceIds);
      print('   ${group.groupName}: $courtName');
    });
    
    print('🎮 Generated ${games.length} group stage games across ${groupCourtAssignments.length} courts');
    return games;
  }

  /// Calculate tier assignments after group stage completion
  static List<TournamentTierModel> calculateTierAssignments({
    required String tournamentId,
    required List<TournamentGroupModel> groups,
    required List<GameModel> completedGames,
    required TieredTournamentStructure structure,
    int winPoints = defaultWinPoints,
    int tiePoints = defaultTiePoints,
    int lossPoints = defaultLossPoints,
  }) {
    final tierAssignments = <TournamentTierModel>[];
    final allGroupStandings = <_GroupStanding>[];

    // Calculate standings for each group
    for (final group in groups) {
      final groupStandings = _calculateGroupStandings(
        group: group,
        games: completedGames,
        winPoints: winPoints,
        tiePoints: tiePoints,
        lossPoints: lossPoints,
      );
      allGroupStandings.addAll(groupStandings);
    }

    // Sort all teams by group position and performance
    final proTeams = <_GroupStanding>[];
    final intermediateTeams = <_GroupStanding>[];
    final noviceTeams = <_GroupStanding>[];

    // Collect teams by group position
    for (int position = 1; position <= structure.groupSize; position++) {
      final teamsAtPosition = allGroupStandings
          .where((standing) => standing.groupPosition == position)
          .toList()
        ..sort(_compareTeamPerformance);

      // Distribute to tiers based on position and structure
      if (position == 1) {
        // 1st place teams go to pro tier
        proTeams.addAll(teamsAtPosition);
      } else if (position == structure.groupSize) {
        // Last place teams go to novice tier
        noviceTeams.addAll(teamsAtPosition);
      } else {
        // Middle teams go to intermediate tier
        intermediateTeams.addAll(teamsAtPosition);
      }
    }

    // Create tier assignments
    tierAssignments.addAll(_createTierAssignments(
      tournamentId: tournamentId,
      teams: proTeams,
      tier: TournamentTier.pro,
    ));

    tierAssignments.addAll(_createTierAssignments(
      tournamentId: tournamentId,
      teams: intermediateTeams,
      tier: TournamentTier.intermediate,
    ));

    tierAssignments.addAll(_createTierAssignments(
      tournamentId: tournamentId,
      teams: noviceTeams,
      tier: TournamentTier.novice,
    ));

    // Eliminate excess teams (lowest performers)
    final totalAssigned = tierAssignments.length;
    if (totalAssigned > structure.usableTeams) {
      print('⚠️ Eliminating ${totalAssigned - structure.usableTeams} lowest-performing teams');
      // Remove lowest-seeded novice teams
      tierAssignments.removeRange(structure.usableTeams, totalAssigned);
    }

    print('🏆 Tier assignments calculated:');
    print('   Pro: ${tierAssignments.where((t) => t.tier == TournamentTier.pro).length} teams');
    print('   Intermediate: ${tierAssignments.where((t) => t.tier == TournamentTier.intermediate).length} teams');
    print('   Novice: ${tierAssignments.where((t) => t.tier == TournamentTier.novice).length} teams');

    return tierAssignments;
  }

  // Private helper methods
  static _TierDistribution _calculateTierDistribution(int numGroups, int groupSize) {
    if (groupSize == 4) {
      return _TierDistribution(
        proTierTeams: numGroups, // 1st place from each group
        intermediateTierTeams: numGroups * 2, // 2nd and 3rd place
        noviceTierTeams: numGroups, // 4th place from each group
      );
    } else if (groupSize == 3) {
      return _TierDistribution(
        proTierTeams: numGroups, // 1st place
        intermediateTierTeams: numGroups, // 2nd place
        noviceTierTeams: numGroups, // 3rd place
      );
    } else {
      // Default distribution
      final proTeams = max(1, numGroups ~/ 3);
      final noviceTeams = max(1, numGroups ~/ 3);
      final intermediateTeams = numGroups - proTeams - noviceTeams;
      
      return _TierDistribution(
        proTierTeams: proTeams,
        intermediateTierTeams: intermediateTeams,
        noviceTierTeams: noviceTeams,
      );
    }
  }

  static void _distributeTeamsSnakeDraft(
    List<TeamModel> teams,
    List<TournamentGroupModel> groups,
  ) {
    for (int i = 0; i < teams.length; i++) {
      final groupIndex = _getSnakeDraftGroupIndex(i, groups.length);
      groups[groupIndex] = groups[groupIndex].copyWith(
        teamIds: [...groups[groupIndex].teamIds, teams[i].id],
      );
    }
  }

  static int _getSnakeDraftGroupIndex(int teamIndex, int numGroups) {
    final round = teamIndex ~/ numGroups;
    final positionInRound = teamIndex % numGroups;
    
    // Even rounds go forward (0,1,2,3), odd rounds go backward (3,2,1,0)
    if (round % 2 == 0) {
      return positionInRound;
    } else {
      return numGroups - 1 - positionInRound;
    }
  }

  static List<GameModel> _generateRoundRobinForGroup({
    required String tournamentId,
    required TournamentGroupModel group,
    required List<String> resourceIds,
    required DateTime startTime,
    required int gameDurationMinutes,
    required int timeBetweenGamesMinutes,
    required int startingGameNumber,
  }) {
    final games = <GameModel>[];
    final teamIds = group.teamIds;
    var gameNumber = startingGameNumber;
    var currentTime = startTime;

    // Generate round-robin matchups
    for (int i = 0; i < teamIds.length; i++) {
      for (int j = i + 1; j < teamIds.length; j++) {
        final resourceIndex = (games.length) % resourceIds.length;
        
        games.add(GameModel(
          id: _uuid.v4(),
          tournamentId: tournamentId,
          team1Id: teamIds[i],
          team2Id: teamIds[j],
          resourceId: resourceIds[resourceIndex],
          scheduledDate: currentTime,
          scheduledTime: '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
          status: GameStatus.scheduled,
          gameNumber: gameNumber,
          notes: 'Group Stage - ${group.groupName}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        gameNumber++;
        currentTime = currentTime.add(Duration(
          minutes: gameDurationMinutes + timeBetweenGamesMinutes,
        ));
      }
    }

    return games;
  }

  static List<GameModel> _generateRoundRobinForGroupOptimized({
    required String tournamentId,
    required TournamentGroupModel group,
    required String assignedResourceId,
    required DateTime startTime,
    required int gameDurationMinutes,
    required int timeBetweenGamesMinutes,
    required int startingGameNumber,
  }) {
    final games = <GameModel>[];
    final teamIds = group.teamIds;
    var gameNumber = startingGameNumber;
    var currentTime = startTime;

    // Generate round-robin matchups - all games for this group use the assigned court
    for (int i = 0; i < teamIds.length; i++) {
      for (int j = i + 1; j < teamIds.length; j++) {
        games.add(GameModel(
          id: _uuid.v4(),
          tournamentId: tournamentId,
          team1Id: teamIds[i],
          team2Id: teamIds[j],
          resourceId: assignedResourceId, // Use assigned court only
          scheduledDate: currentTime,
          scheduledTime: '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
          status: GameStatus.scheduled,
          gameNumber: gameNumber,
          notes: 'Group Stage - ${group.groupName}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        gameNumber++;
        currentTime = currentTime.add(Duration(
          minutes: gameDurationMinutes + timeBetweenGamesMinutes,
        ));
      }
    }

    return games;
  }

  static String _getCourtName(String resourceId, List<String> allResourceIds) {
    // Try to find the index and create a meaningful name
    final index = allResourceIds.indexOf(resourceId);
    if (index != -1) {
      return 'Court ${index + 1}';
    }
    return 'Court ${resourceId.substring(0, 8)}...'; // Fallback to partial ID
  }

  static DateTime _parseGameDateTime(DateTime date, String time) {
    final timeParts = time.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  static List<_GroupStanding> _calculateGroupStandings({
    required TournamentGroupModel group,
    required List<GameModel> games,
    required int winPoints,
    required int tiePoints,
    required int lossPoints,
  }) {
    final standings = <String, _GroupStanding>{};
    
    // Initialize standings for all teams in group
    for (final teamId in group.teamIds) {
      standings[teamId] = _GroupStanding(
        teamId: teamId,
        groupId: group.id,
        points: 0,
        wins: 0,
        ties: 0,
        losses: 0,
        pointsFor: 0,
        pointsAgainst: 0,
        groupPosition: 0,
      );
    }

    // Process completed games for this group
    final groupGames = games.where((game) => 
      group.teamIds.contains(game.team1Id) && 
      group.teamIds.contains(game.team2Id) &&
      game.status == GameStatus.completed
    );

    for (final game in groupGames) {
      // Skip games without valid team IDs
      if (game.team1Id == null || game.team2Id == null) continue;
      
      final team1Id = game.team1Id!;
      final team2Id = game.team2Id!;
      final team1Standing = standings[team1Id]!;
      final team2Standing = standings[team2Id]!;

      if (game.team1Score != null && game.team2Score != null) {
        final team1Score = game.team1Score!;
        final team2Score = game.team2Score!;

        // Update point differential
        standings[team1Id] = team1Standing.copyWith(
          pointsFor: team1Standing.pointsFor + team1Score,
          pointsAgainst: team1Standing.pointsAgainst + team2Score,
        );
        
        standings[team2Id] = team2Standing.copyWith(
          pointsFor: team2Standing.pointsFor + team2Score,
          pointsAgainst: team2Standing.pointsAgainst + team1Score,
        );

        // Determine winner and update standings
        if (team1Score > team2Score) {
          // Team 1 wins
          standings[team1Id] = standings[team1Id]!.copyWith(
            points: standings[team1Id]!.points + winPoints,
            wins: standings[team1Id]!.wins + 1,
          );
          standings[team2Id] = standings[team2Id]!.copyWith(
            points: standings[team2Id]!.points + lossPoints,
            losses: standings[team2Id]!.losses + 1,
          );
        } else if (team2Score > team1Score) {
          // Team 2 wins
          standings[team2Id] = standings[team2Id]!.copyWith(
            points: standings[team2Id]!.points + winPoints,
            wins: standings[team2Id]!.wins + 1,
          );
          standings[team1Id] = standings[team1Id]!.copyWith(
            points: standings[team1Id]!.points + lossPoints,
            losses: standings[team1Id]!.losses + 1,
          );
        } else {
          // Tie
          standings[team1Id] = standings[team1Id]!.copyWith(
            points: standings[team1Id]!.points + tiePoints,
            ties: standings[team1Id]!.ties + 1,
          );
          standings[team2Id] = standings[team2Id]!.copyWith(
            points: standings[team2Id]!.points + tiePoints,
            ties: standings[team2Id]!.ties + 1,
          );
        }
      }
    }

    // Sort and assign positions
    final sortedStandings = standings.values.toList()
      ..sort(_compareTeamPerformance);

    for (int i = 0; i < sortedStandings.length; i++) {
      final standing = sortedStandings[i];
      sortedStandings[i] = standing.copyWith(groupPosition: i + 1);
    }

    return sortedStandings;
  }

  static int _compareTeamPerformance(_GroupStanding a, _GroupStanding b) {
    // Primary: Total points
    if (a.points != b.points) {
      return b.points.compareTo(a.points);
    }
    
    // Secondary: Point differential
    final aDiff = a.pointsFor - a.pointsAgainst;
    final bDiff = b.pointsFor - b.pointsAgainst;
    if (aDiff != bDiff) {
      return bDiff.compareTo(aDiff);
    }
    
    // Tertiary: Points scored
    if (a.pointsFor != b.pointsFor) {
      return b.pointsFor.compareTo(a.pointsFor);
    }

    // Final: Win percentage
    final aWinPct = a.gamesPlayed > 0 ? a.wins / a.gamesPlayed : 0.0;
    final bWinPct = b.gamesPlayed > 0 ? b.wins / b.gamesPlayed : 0.0;
    return bWinPct.compareTo(aWinPct);
  }

  static List<TournamentTierModel> _createTierAssignments({
    required String tournamentId,
    required List<_GroupStanding> teams,
    required TournamentTier tier,
  }) {
    final assignments = <TournamentTierModel>[];
    
    for (int i = 0; i < teams.length; i++) {
      final standing = teams[i];
      assignments.add(TournamentTierModel(
        id: _uuid.v4(),
        tournamentId: tournamentId,
        teamId: standing.teamId,
        tierValue: tier.value,
        groupPosition: standing.groupPosition,
        groupPoints: standing.points,
        pointDifferential: standing.pointsFor - standing.pointsAgainst,
        tierSeed: i + 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    return assignments;
  }
}

// Helper classes
class TieredTournamentStructure {
  const TieredTournamentStructure({
    required this.totalTeams,
    required this.usableTeams,
    required this.eliminatedTeams,
    required this.numGroups,
    required this.groupSize,
    required this.proTierTeams,
    required this.intermediateTierTeams,
    required this.noviceTierTeams,
  });

  final int totalTeams;
  final int usableTeams;
  final int eliminatedTeams;
  final int numGroups;
  final int groupSize;
  final int proTierTeams;
  final int intermediateTierTeams;
  final int noviceTierTeams;
}

class _TierDistribution {
  const _TierDistribution({
    required this.proTierTeams,
    required this.intermediateTierTeams,
    required this.noviceTierTeams,
  });

  final int proTierTeams;
  final int intermediateTierTeams;
  final int noviceTierTeams;
}

class _GroupStanding {
  const _GroupStanding({
    required this.teamId,
    required this.groupId,
    required this.points,
    required this.wins,
    required this.ties,
    required this.losses,
    required this.pointsFor,
    required this.pointsAgainst,
    required this.groupPosition,
  });

  final String teamId;
  final String groupId;
  final int points;
  final int wins;
  final int ties;
  final int losses;
  final int pointsFor;
  final int pointsAgainst;
  final int groupPosition;

  int get gamesPlayed => wins + ties + losses;

  _GroupStanding copyWith({
    String? teamId,
    String? groupId,
    int? points,
    int? wins,
    int? ties,
    int? losses,
    int? pointsFor,
    int? pointsAgainst,
    int? groupPosition,
  }) {
    return _GroupStanding(
      teamId: teamId ?? this.teamId,
      groupId: groupId ?? this.groupId,
      points: points ?? this.points,
      wins: wins ?? this.wins,
      ties: ties ?? this.ties,
      losses: losses ?? this.losses,
      pointsFor: pointsFor ?? this.pointsFor,
      pointsAgainst: pointsAgainst ?? this.pointsAgainst,
      groupPosition: groupPosition ?? this.groupPosition,
    );
  }
} 