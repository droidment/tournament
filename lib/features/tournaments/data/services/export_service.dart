import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../../../../core/models/game_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/tournament_resource_model.dart';
import '../../../../core/models/tournament_standings_model.dart';

enum ExportFormat { csv, json, txt, html }

class ExportService {
  /// Export tournament schedule in various formats
  static Future<void> exportSchedule({
    required String tournamentName,
    required List<GameModel> games,
    required Map<String, TeamModel> teamMap,
    required Map<String, TournamentResourceModel> resourceMap,
    required ExportFormat format,
  }) async {
    String content;
    String filename;
    String mimeType;

    switch (format) {
      case ExportFormat.csv:
        content = _generateScheduleCSV(games, teamMap, resourceMap);
        filename = '${tournamentName}_schedule.csv';
        mimeType = 'text/csv';
        break;
      case ExportFormat.json:
        content = _generateScheduleJSON(tournamentName, games, teamMap, resourceMap);
        filename = '${tournamentName}_schedule.json';
        mimeType = 'application/json';
        break;
      case ExportFormat.txt:
        content = _generateScheduleTXT(tournamentName, games, teamMap, resourceMap);
        filename = '${tournamentName}_schedule.txt';
        mimeType = 'text/plain';
        break;
      case ExportFormat.html:
        content = _generateScheduleHTML(tournamentName, games, teamMap, resourceMap);
        filename = '${tournamentName}_schedule.html';
        mimeType = 'text/html';
        break;
    }

    await _downloadFile(content, filename, mimeType);
  }

  /// Export tournament standings in various formats
  static Future<void> exportStandings({
    required String tournamentName,
    required TournamentStandingsModel standings,
    required ExportFormat format,
  }) async {
    String content;
    String filename;
    String mimeType;

    switch (format) {
      case ExportFormat.csv:
        content = _generateStandingsCSV(standings);
        filename = '${tournamentName}_standings.csv';
        mimeType = 'text/csv';
        break;
      case ExportFormat.json:
        content = _generateStandingsJSON(tournamentName, standings);
        filename = '${tournamentName}_standings.json';
        mimeType = 'application/json';
        break;
      case ExportFormat.txt:
        content = _generateStandingsTXT(tournamentName, standings);
        filename = '${tournamentName}_standings.txt';
        mimeType = 'text/plain';
        break;
      case ExportFormat.html:
        content = _generateStandingsHTML(tournamentName, standings);
        filename = '${tournamentName}_standings.html';
        mimeType = 'text/html';
        break;
    }

    await _downloadFile(content, filename, mimeType);
  }

  /// Export complete tournament data
  static Future<void> exportTournamentComplete({
    required String tournamentName,
    required List<GameModel> games,
    required Map<String, TeamModel> teamMap,
    required Map<String, TournamentResourceModel> resourceMap,
    required TournamentStandingsModel standings,
    required ExportFormat format,
  }) async {
    String content;
    String filename;
    String mimeType;

    switch (format) {
      case ExportFormat.json:
        content = _generateCompleteJSON(tournamentName, games, teamMap, resourceMap, standings);
        filename = '${tournamentName}_complete.json';
        mimeType = 'application/json';
        break;
      case ExportFormat.html:
        content = _generateCompleteHTML(tournamentName, games, teamMap, resourceMap, standings);
        filename = '${tournamentName}_complete.html';
        mimeType = 'text/html';
        break;
      default:
        throw ArgumentError('Complete export only supports JSON and HTML formats');
    }

    await _downloadFile(content, filename, mimeType);
  }

  // Private methods for generating different formats

  static String _generateScheduleCSV(
    List<GameModel> games,
    Map<String, TeamModel> teamMap,
    Map<String, TournamentResourceModel> resourceMap,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Game ID,Date,Time,Team 1,Team 2,Resource,Status,Score 1,Score 2,Winner');

    for (final game in games) {
      final team1 = teamMap[game.team1Id]?.name ?? 'Team 1';
      final team2 = teamMap[game.team2Id]?.name ?? 'Team 2';
      final resource = resourceMap[game.resourceId]?.name ?? 'Unknown';
      final date = game.scheduledDate?.toLocal().toString().split(' ')[0] ?? '';
      final time = game.scheduledTime ?? '';
      final status = game.status.name;
      final score1 = game.team1Score?.toString() ?? '';
      final score2 = game.team2Score?.toString() ?? '';
      final winner = game.winnerId != null ? teamMap[game.winnerId!]?.name ?? 'Unknown' : '';

      buffer.writeln('${game.id},$date,$time,"$team1","$team2","$resource",$status,$score1,$score2,"$winner"');
    }

    return buffer.toString();
  }

  static String _generateScheduleJSON(
    String tournamentName,
    List<GameModel> games,
    Map<String, TeamModel> teamMap,
    Map<String, TournamentResourceModel> resourceMap,
  ) {
    final exportData = {
      'tournament': tournamentName,
      'exportDate': DateTime.now().toIso8601String(),
      'totalGames': games.length,
      'games': games.map((game) => {
        'id': game.id,
        'date': game.scheduledDate?.toIso8601String(),
        'time': game.scheduledTime,
        'team1': {
          'id': game.team1Id,
          'name': teamMap[game.team1Id]?.name ?? 'Team 1',
        },
        'team2': {
          'id': game.team2Id,
          'name': teamMap[game.team2Id]?.name ?? 'Team 2',
        },
        'resource': {
          'id': game.resourceId,
          'name': resourceMap[game.resourceId]?.name ?? 'Unknown',
        },
        'status': game.status.name,
        'scores': {
          'team1': game.team1Score,
          'team2': game.team2Score,
        },
        'winner': game.winnerId != null ? teamMap[game.winnerId!]?.name : null,
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  static String _generateScheduleTXT(
    String tournamentName,
    List<GameModel> games,
    Map<String, TeamModel> teamMap,
    Map<String, TournamentResourceModel> resourceMap,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('=' * 60);
    buffer.writeln('${tournamentName.toUpperCase()} - TOURNAMENT SCHEDULE');
    buffer.writeln('=' * 60);
    buffer.writeln('Generated: ${DateTime.now().toString()}');
    buffer.writeln('Total Games: ${games.length}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    // Group games by date
    final gamesByDate = <String, List<GameModel>>{};
    for (final game in games) {
      final dateKey = game.scheduledDate?.toLocal().toString().split(' ')[0] ?? 'No Date';
      gamesByDate.putIfAbsent(dateKey, () => []).add(game);
    }

    for (final entry in gamesByDate.entries) {
      buffer.writeln('📅 ${entry.key}');
      buffer.writeln('-' * 40);
      
      final sortedGames = entry.value..sort((a, b) => (a.scheduledTime ?? '').compareTo(b.scheduledTime ?? ''));
      
      for (final game in sortedGames) {
        final team1 = teamMap[game.team1Id]?.name ?? 'Team 1';
        final team2 = teamMap[game.team2Id]?.name ?? 'Team 2';
        final resource = resourceMap[game.resourceId]?.name ?? 'Unknown';
        final time = game.scheduledTime ?? 'TBD';
        
        buffer.writeln('🕐 $time - $resource');
        buffer.writeln('   $team1 vs $team2');
        
        if (game.status == GameStatus.completed) {
          final score1 = game.team1Score ?? 0;
          final score2 = game.team2Score ?? 0;
          final winner = game.winnerId != null ? teamMap[game.winnerId!]?.name : 'Draw';
          buffer.writeln('   Score: $score1 - $score2 (Winner: $winner)');
        } else {
          buffer.writeln('   Status: ${game.status.name}');
        }
        
        buffer.writeln();
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _generateScheduleHTML(
    String tournamentName,
    List<GameModel> games,
    Map<String, TeamModel> teamMap,
    Map<String, TournamentResourceModel> resourceMap,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>$tournamentName - Tournament Schedule</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }');
    buffer.writeln('    .header { text-align: center; color: #333; margin-bottom: 30px; }');
    buffer.writeln('    .date-section { margin-bottom: 30px; }');
    buffer.writeln('    .date-header { background: #2196F3; color: white; padding: 10px; border-radius: 5px; margin-bottom: 15px; }');
    buffer.writeln('    .game-card { background: white; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin-bottom: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }');
    buffer.writeln('    .game-time { font-weight: bold; color: #666; }');
    buffer.writeln('    .game-teams { font-size: 18px; margin: 5px 0; }');
    buffer.writeln('    .game-resource { color: #888; font-size: 14px; }');
    buffer.writeln('    .game-score { background: #4CAF50; color: white; padding: 5px 10px; border-radius: 3px; display: inline-block; margin-top: 5px; }');
    buffer.writeln('    .status-completed { color: #4CAF50; }');
    buffer.writeln('    .status-in-progress { color: #FF9800; }');
    buffer.writeln('    .status-scheduled { color: #2196F3; }');
    buffer.writeln('    @media print { body { background: white; } .game-card { box-shadow: none; } }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="header">');
    buffer.writeln('    <h1>$tournamentName</h1>');
    buffer.writeln('    <h2>Tournament Schedule</h2>');
    buffer.writeln('    <p>Generated: ${DateTime.now().toString()}</p>');
    buffer.writeln('    <p>Total Games: ${games.length}</p>');
    buffer.writeln('  </div>');

    // Group games by date
    final gamesByDate = <String, List<GameModel>>{};
    for (final game in games) {
      final dateKey = game.scheduledDate?.toLocal().toString().split(' ')[0] ?? 'No Date';
      gamesByDate.putIfAbsent(dateKey, () => []).add(game);
    }

    for (final entry in gamesByDate.entries) {
      buffer.writeln('  <div class="date-section">');
      buffer.writeln('    <div class="date-header">');
      buffer.writeln('      <h3>📅 ${entry.key}</h3>');
      buffer.writeln('    </div>');
      
      final sortedGames = entry.value..sort((a, b) => (a.scheduledTime ?? '').compareTo(b.scheduledTime ?? ''));
      
      for (final game in sortedGames) {
        final team1 = teamMap[game.team1Id]?.name ?? 'Team 1';
        final team2 = teamMap[game.team2Id]?.name ?? 'Team 2';
        final resource = resourceMap[game.resourceId]?.name ?? 'Unknown';
        final time = game.scheduledTime ?? 'TBD';
        
        buffer.writeln('    <div class="game-card">');
        buffer.writeln('      <div class="game-time">🕐 $time</div>');
        buffer.writeln('      <div class="game-teams">$team1 vs $team2</div>');
        buffer.writeln('      <div class="game-resource">📍 $resource</div>');
        
        if (game.status == GameStatus.completed && game.team1Score != null && game.team2Score != null) {
          final winner = game.winnerId != null ? teamMap[game.winnerId!]?.name : 'Draw';
          buffer.writeln('      <div class="game-score">Score: ${game.team1Score} - ${game.team2Score} (Winner: $winner)</div>');
        } else {
          final statusClass = 'status-${game.status.name.replaceAll('_', '-')}';
          buffer.writeln('      <div class="$statusClass">Status: ${game.status.name}</div>');
        }
        
        buffer.writeln('    </div>');
      }
      buffer.writeln('  </div>');
    }

    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  static String _generateStandingsCSV(TournamentStandingsModel standings) {
    final buffer = StringBuffer();
    buffer.writeln('Position,Team,Points,Games Played,Wins,Losses,Draws,Points For,Points Against,Point Difference,Win %');

    for (final team in standings.teamStandings) {
      buffer.writeln('${team.position},"${team.teamName}",${team.points},${team.gamesPlayed},${team.wins},${team.losses},${team.draws},${team.pointsFor},${team.pointsAgainst},${team.pointsDifference},${(team.winPercentage * 100).toStringAsFixed(1)}%');
    }

    return buffer.toString();
  }

  static String _generateStandingsJSON(String tournamentName, TournamentStandingsModel standings) {
    final exportData = {
      'tournament': tournamentName,
      'exportDate': DateTime.now().toIso8601String(),
      'format': standings.format.name,
      'totalTeams': standings.teamStandings.length,
      'standings': standings.teamStandings.map((team) => {
        'position': team.position,
        'teamId': team.teamId,
        'teamName': team.teamName,
        'points': team.points,
        'gamesPlayed': team.gamesPlayed,
        'wins': team.wins,
        'losses': team.losses,
        'draws': team.draws,
        'pointsFor': team.pointsFor,
        'pointsAgainst': team.pointsAgainst,
        'pointsDifference': team.pointsDifference,
        'winPercentage': team.winPercentage,
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  static String _generateStandingsTXT(String tournamentName, TournamentStandingsModel standings) {
    final buffer = StringBuffer();
    buffer.writeln('=' * 80);
    buffer.writeln('${tournamentName.toUpperCase()} - TOURNAMENT STANDINGS');
    buffer.writeln('=' * 80);
    buffer.writeln('Generated: ${DateTime.now().toString()}');
    buffer.writeln('Format: ${standings.format.name}');
    buffer.writeln('Total Teams: ${standings.teamStandings.length}');
    buffer.writeln('=' * 80);
    buffer.writeln();

    // Header
    buffer.writeln('Pos  Team                         Pts  GP  W   L   D   PF   PA   +/-   Win%');
    buffer.writeln('-' * 80);

    for (final team in standings.teamStandings) {
      final pos = team.position.toString().padLeft(3);
      final name = team.teamName.length > 25 ? '${team.teamName.substring(0, 22)}...' : team.teamName.padRight(25);
      final pts = team.points.toString().padLeft(3);
      final gp = team.gamesPlayed.toString().padLeft(3);
      final w = team.wins.toString().padLeft(3);
      final l = team.losses.toString().padLeft(3);
      final d = team.draws.toString().padLeft(3);
      final pf = team.pointsFor.toString().padLeft(4);
      final pa = team.pointsAgainst.toString().padLeft(4);
      final diff = (team.pointsDifference >= 0 ? '+${team.pointsDifference}' : team.pointsDifference.toString()).padLeft(5);
      final winPct = '${(team.winPercentage * 100).toStringAsFixed(1)}%'.padLeft(5);

      buffer.writeln('$pos  $name $pts  $gp  $w   $l   $d   $pf   $pa   $diff $winPct');
    }

    return buffer.toString();
  }

  static String _generateStandingsHTML(String tournamentName, TournamentStandingsModel standings) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>$tournamentName - Tournament Standings</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }');
    buffer.writeln('    .header { text-align: center; color: #333; margin-bottom: 30px; }');
    buffer.writeln('    .standings-table { width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }');
    buffer.writeln('    .standings-table th { background: #2196F3; color: white; padding: 12px; text-align: left; font-weight: bold; }');
    buffer.writeln('    .standings-table td { padding: 10px 12px; border-bottom: 1px solid #eee; }');
    buffer.writeln('    .standings-table tr:nth-child(even) { background: #f9f9f9; }');
    buffer.writeln('    .standings-table tr:hover { background: #e3f2fd; }');
    buffer.writeln('    .position { font-weight: bold; color: #2196F3; text-align: center; }');
    buffer.writeln('    .team-name { font-weight: bold; }');
    buffer.writeln('    .points { font-weight: bold; color: #4CAF50; text-align: center; }');
    buffer.writeln('    .numeric { text-align: center; }');
    buffer.writeln('    .positive { color: #4CAF50; }');
    buffer.writeln('    .negative { color: #f44336; }');
    buffer.writeln('    @media print { body { background: white; } .standings-table { box-shadow: none; } }');
    buffer.writeln('    @media (max-width: 768px) { .standings-table { font-size: 12px; } .standings-table th, .standings-table td { padding: 6px; } }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="header">');
    buffer.writeln('    <h1>$tournamentName</h1>');
    buffer.writeln('    <h2>🏆 Tournament Standings</h2>');
    buffer.writeln('    <p>Generated: ${DateTime.now().toString()}</p>');
    buffer.writeln('    <p>Format: ${standings.format.name} | Total Teams: ${standings.teamStandings.length}</p>');
    buffer.writeln('  </div>');

    buffer.writeln('  <table class="standings-table">');
    buffer.writeln('    <thead>');
    buffer.writeln('      <tr>');
    buffer.writeln('        <th class="numeric">Pos</th>');
    buffer.writeln('        <th>Team</th>');
    buffer.writeln('        <th class="numeric">Pts</th>');
    buffer.writeln('        <th class="numeric">GP</th>');
    buffer.writeln('        <th class="numeric">W</th>');
    buffer.writeln('        <th class="numeric">L</th>');
    buffer.writeln('        <th class="numeric">D</th>');
    buffer.writeln('        <th class="numeric">PF</th>');
    buffer.writeln('        <th class="numeric">PA</th>');
    buffer.writeln('        <th class="numeric">+/-</th>');
    buffer.writeln('        <th class="numeric">Win%</th>');
    buffer.writeln('      </tr>');
    buffer.writeln('    </thead>');
    buffer.writeln('    <tbody>');

    for (final team in standings.teamStandings) {
      final diffClass = team.pointsDifference >= 0 ? 'positive' : 'negative';
      final diffText = team.pointsDifference >= 0 ? '+${team.pointsDifference}' : team.pointsDifference.toString();
      
      buffer.writeln('      <tr>');
      buffer.writeln('        <td class="position">${team.position}</td>');
      buffer.writeln('        <td class="team-name">${team.teamName}</td>');
      buffer.writeln('        <td class="points">${team.points}</td>');
      buffer.writeln('        <td class="numeric">${team.gamesPlayed}</td>');
      buffer.writeln('        <td class="numeric">${team.wins}</td>');
      buffer.writeln('        <td class="numeric">${team.losses}</td>');
      buffer.writeln('        <td class="numeric">${team.draws}</td>');
      buffer.writeln('        <td class="numeric">${team.pointsFor}</td>');
      buffer.writeln('        <td class="numeric">${team.pointsAgainst}</td>');
      buffer.writeln('        <td class="numeric $diffClass">$diffText</td>');
      buffer.writeln('        <td class="numeric">${(team.winPercentage * 100).toStringAsFixed(1)}%</td>');
      buffer.writeln('      </tr>');
    }

    buffer.writeln('    </tbody>');
    buffer.writeln('  </table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  static String _generateCompleteJSON(
    String tournamentName,
    List<GameModel> games,
    Map<String, TeamModel> teamMap,
    Map<String, TournamentResourceModel> resourceMap,
    TournamentStandingsModel standings,
  ) {
    final exportData = {
      'tournament': {
        'name': tournamentName,
        'exportDate': DateTime.now().toIso8601String(),
        'totalGames': games.length,
        'totalTeams': teamMap.length,
        'totalResources': resourceMap.length,
      },
      'teams': teamMap.values.map((team) => {
        'id': team.id,
        'name': team.name,
        'categoryId': team.categoryId,
        'seed': team.seed,
        'isActive': team.isActive,
      }).toList(),
      'resources': resourceMap.values.map((resource) => {
        'id': resource.id,
        'name': resource.name,
        'type': resource.type,
        'capacity': resource.capacity,
      }).toList(),
      'standings': {
        'format': standings.format.name,
        'teams': standings.teamStandings.map((team) => {
          'position': team.position,
          'teamId': team.teamId,
          'teamName': team.teamName,
          'points': team.points,
          'gamesPlayed': team.gamesPlayed,
          'wins': team.wins,
          'losses': team.losses,
          'draws': team.draws,
          'pointsFor': team.pointsFor,
          'pointsAgainst': team.pointsAgainst,
          'pointsDifference': team.pointsDifference,
          'winPercentage': team.winPercentage,
        }).toList(),
      },
      'schedule': games.map((game) => {
        'id': game.id,
        'date': game.scheduledDate?.toIso8601String(),
        'time': game.scheduledTime,
        'team1': {
          'id': game.team1Id,
          'name': teamMap[game.team1Id]?.name ?? 'Team 1',
        },
        'team2': {
          'id': game.team2Id,
          'name': teamMap[game.team2Id]?.name ?? 'Team 2',
        },
        'resource': {
          'id': game.resourceId,
          'name': resourceMap[game.resourceId]?.name ?? 'Unknown',
        },
        'status': game.status.name,
        'scores': {
          'team1': game.team1Score,
          'team2': game.team2Score,
        },
        'winner': game.winnerId != null ? teamMap[game.winnerId!]?.name : null,
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  static String _generateCompleteHTML(
    String tournamentName,
    List<GameModel> games,
    Map<String, TeamModel> teamMap,
    Map<String, TournamentResourceModel> resourceMap,
    TournamentStandingsModel standings,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>$tournamentName - Complete Tournament Report</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; line-height: 1.6; }');
    buffer.writeln('    .container { max-width: 1200px; margin: 0 auto; }');
    buffer.writeln('    .header { text-align: center; color: #333; margin-bottom: 40px; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }');
    buffer.writeln('    .section { background: white; margin-bottom: 30px; padding: 25px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }');
    buffer.writeln('    .section h2 { color: #2196F3; border-bottom: 2px solid #2196F3; padding-bottom: 10px; margin-bottom: 20px; }');
    buffer.writeln('    .table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }');
    buffer.writeln('    .table th { background: #f5f5f5; padding: 12px; text-align: left; font-weight: bold; border: 1px solid #ddd; }');
    buffer.writeln('    .table td { padding: 10px 12px; border: 1px solid #ddd; }');
    buffer.writeln('    .table tr:nth-child(even) { background: #f9f9f9; }');
    buffer.writeln('    .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 20px; }');
    buffer.writeln('    .stat-card { background: #e3f2fd; padding: 20px; border-radius: 8px; text-align: center; }');
    buffer.writeln('    .stat-number { font-size: 2em; font-weight: bold; color: #2196F3; }');
    buffer.writeln('    .stat-label { color: #666; margin-top: 5px; }');
    buffer.writeln('    @media print { body { background: white; } .section { box-shadow: none; page-break-inside: avoid; } }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="container">');
    
    // Header
    buffer.writeln('    <div class="header">');
    buffer.writeln('      <h1>🏆 $tournamentName</h1>');
    buffer.writeln('      <h2>Complete Tournament Report</h2>');
    buffer.writeln('      <p>Generated: ${DateTime.now().toString()}</p>');
    buffer.writeln('    </div>');

    // Statistics overview
    buffer.writeln('    <div class="section">');
    buffer.writeln('      <h2>📊 Tournament Statistics</h2>');
    buffer.writeln('      <div class="stats-grid">');
    buffer.writeln('        <div class="stat-card">');
    buffer.writeln('          <div class="stat-number">${teamMap.length}</div>');
    buffer.writeln('          <div class="stat-label">Teams</div>');
    buffer.writeln('        </div>');
    buffer.writeln('        <div class="stat-card">');
    buffer.writeln('          <div class="stat-number">${games.length}</div>');
    buffer.writeln('          <div class="stat-label">Total Games</div>');
    buffer.writeln('        </div>');
    buffer.writeln('        <div class="stat-card">');
    buffer.writeln('          <div class="stat-number">${games.where((g) => g.status == GameStatus.completed).length}</div>');
    buffer.writeln('          <div class="stat-label">Completed</div>');
    buffer.writeln('        </div>');
    buffer.writeln('        <div class="stat-card">');
    buffer.writeln('          <div class="stat-number">${resourceMap.length}</div>');
    buffer.writeln('          <div class="stat-label">Resources</div>');
    buffer.writeln('        </div>');
    buffer.writeln('      </div>');
    buffer.writeln('    </div>');

    // Standings section
    buffer.writeln('    <div class="section">');
    buffer.writeln('      <h2>🏆 Final Standings</h2>');
    buffer.writeln(_generateStandingsHTML(tournamentName, standings).split('<body>')[1].split('</body>')[0]);
    buffer.writeln('    </div>');

    // Schedule section (condensed)
    buffer.writeln('    <div class="section">');
    buffer.writeln('      <h2>📅 Tournament Schedule</h2>');
    buffer.writeln('      <table class="table">');
    buffer.writeln('        <thead>');
    buffer.writeln('          <tr>');
    buffer.writeln('            <th>Date</th>');
    buffer.writeln('            <th>Time</th>');
    buffer.writeln('            <th>Teams</th>');
    buffer.writeln('            <th>Resource</th>');
    buffer.writeln('            <th>Status</th>');
    buffer.writeln('            <th>Score</th>');
    buffer.writeln('          </tr>');
    buffer.writeln('        </thead>');
    buffer.writeln('        <tbody>');
    
    for (final game in games) {
      final team1 = teamMap[game.team1Id]?.name ?? 'Team 1';
      final team2 = teamMap[game.team2Id]?.name ?? 'Team 2';
      final resource = resourceMap[game.resourceId]?.name ?? 'Unknown';
      final date = game.scheduledDate?.toLocal().toString().split(' ')[0] ?? 'TBD';
      final time = game.scheduledTime ?? 'TBD';
      final score = game.status == GameStatus.completed 
          ? '${game.team1Score ?? 0} - ${game.team2Score ?? 0}'
          : '-';
      
      buffer.writeln('          <tr>');
      buffer.writeln('            <td>$date</td>');
      buffer.writeln('            <td>$time</td>');
      buffer.writeln('            <td>$team1 vs $team2</td>');
      buffer.writeln('            <td>$resource</td>');
      buffer.writeln('            <td>${game.status.name}</td>');
      buffer.writeln('            <td>$score</td>');
      buffer.writeln('          </tr>');
    }
    
    buffer.writeln('        </tbody>');
    buffer.writeln('      </table>');
    buffer.writeln('    </div>');

    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  // Helper method to download file (web only)
  static Future<void> _downloadFile(String content, String filename, String mimeType) async {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..download = filename
        ..click();
      
      html.Url.revokeObjectUrl(url);
    } else {
      // For non-web platforms, you could implement file saving to device storage
      throw UnsupportedError('File download not implemented for this platform');
    }
  }
} 