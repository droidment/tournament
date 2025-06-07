import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:teamapp3/core/models/team_model.dart';
import 'package:teamapp3/core/models/tournament_resource_model.dart';
import 'package:teamapp3/features/tournaments/data/repositories/team_repository.dart';
import 'package:teamapp3/features/tournaments/data/repositories/tournament_resource_repository.dart';
import 'package:uuid/uuid.dart';

class TeamImportExportService {
  final TeamRepository _teamRepository = TeamRepository();
  final TournamentResourceRepository _resourceRepository = TournamentResourceRepository();
  final Uuid _uuid = const Uuid();

  /// Export teams and resources from a tournament to JSON
  Future<ExportResult> exportTournamentData(String tournamentId) async {
    try {
      final teams = await _teamRepository.getTournamentTeams(tournamentId);
      final resources = await _resourceRepository.getTournamentResources(tournamentId);
      
      final exportData = {
        'version': '1.1',
        'exportedAt': DateTime.now().toIso8601String(),
        'teams': teams.map((team) => {
          'name': team.name,
          'description': team.description,
          'contactEmail': team.contactEmail,
          'contactPhone': team.contactPhone,
          'seed': team.seed,
          'color': team.color?.value.toString(),
        }).toList(),
        'resources': resources.map((resource) => {
          'name': resource.name,
          'type': resource.type,
          'description': resource.description,
          'capacity': resource.capacity,
          'location': resource.location,
        }).toList(),
      };
      
      return ExportResult(
        jsonData: json.encode(exportData),
        teamsCount: teams.length,
        resourcesCount: resources.length,
      );
    } catch (e) {
      throw Exception('Failed to export tournament data: $e');
    }
  }

  /// Pick and parse JSON file for import
  Future<ImportResult?> pickAndParseImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      String jsonContent;
      if (file.bytes != null) {
        // Web platform
        jsonContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        // Mobile/Desktop platform
        final fileObj = File(file.path!);
        jsonContent = await fileObj.readAsString();
      } else {
        throw Exception('Unable to read file');
      }

      return parseImportData(jsonContent);
    } catch (e) {
      throw Exception('Failed to pick and parse file: $e');
    }
  }

  /// Parse JSON data for import
  ImportResult parseImportData(String jsonContent) {
    try {
      final data = json.decode(jsonContent);
      
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid JSON format');
      }

      final List<ImportTeamData> teams = [];
      final List<ImportResourceData> resources = [];
      final List<String> warnings = [];

      // Parse teams
      if (data['teams'] is List) {
        final teamsList = data['teams'] as List;
        for (final teamData in teamsList) {
          if (teamData is Map<String, dynamic>) {
            final teamName = teamData['name'] as String?;
            if (teamName == null || teamName.trim().isEmpty) {
              warnings.add('Skipping team with empty name');
              continue;
            }
            
            teams.add(ImportTeamData(
              name: teamName.trim(),
              description: teamData['description'] as String?,
              contactEmail: teamData['contactEmail'] as String?,
              contactPhone: teamData['contactPhone'] as String?,
              seed: teamData['seed'] as int?,
              colorValue: teamData['color'] as String?,
            ));
          }
        }
      }

      // Parse resources
      if (data['resources'] is List) {
        final resourcesList = data['resources'] as List;
        for (final resourceData in resourcesList) {
          if (resourceData is Map<String, dynamic>) {
            final resourceName = resourceData['name'] as String?;
            final resourceType = resourceData['type'] as String?;
            
            if (resourceName == null || resourceName.trim().isEmpty) {
              warnings.add('Skipping resource with empty name');
              continue;
            }
            
            if (resourceType == null || resourceType.trim().isEmpty) {
              warnings.add('Skipping resource "${resourceName}" with empty type');
              continue;
            }
            
            resources.add(ImportResourceData(
              name: resourceName.trim(),
              type: resourceType.trim(),
              description: resourceData['description'] as String?,
              capacity: resourceData['capacity'] as int?,
              location: resourceData['location'] as String?,
            ));
          }
        }
      }

      if (teams.isEmpty && resources.isEmpty) {
        throw Exception('No valid teams or resources found in the file');
      }

      return ImportResult(
        teams: teams,
        resources: resources,
        warnings: warnings,
      );
    } catch (e) {
      throw Exception('Failed to parse import data: $e');
    }
  }

  /// Import teams and resources into a tournament
  Future<ImportSummary> importTournamentData(
    String tournamentId,
    ImportResult importResult,
    String format,
  ) async {
    try {
      final List<TeamModel> createdTeams = [];
      final List<TournamentResourceModel> createdResources = [];
      final List<String> skippedTeams = [];
      final List<String> skippedResources = [];

      // Apply tiered tournament requirements if needed
      List<ImportTeamData> processedTeams = importResult.teams;
      if (format == 'tiered') {
        processedTeams = applyTieredTournamentRequirements(importResult.teams);
      }

      // Check for duplicate team names
      final existingTeams = await _teamRepository.getTournamentTeams(tournamentId);
      final existingTeamNames = existingTeams.map((t) => t.name.toLowerCase()).toSet();

      // Check for duplicate resource names
      final existingResources = await _resourceRepository.getTournamentResources(tournamentId);
      final existingResourceNames = existingResources.map((r) => r.name.toLowerCase()).toSet();

      // Import teams
      for (final teamData in processedTeams) {
        if (existingTeamNames.contains(teamData.name.toLowerCase())) {
          skippedTeams.add('${teamData.name} (already exists)');
          continue;
        }

        try {
          final team = await _teamRepository.createTeam(
            tournamentId: tournamentId,
            name: teamData.name,
            description: teamData.description,
            contactEmail: teamData.contactEmail,
            contactPhone: teamData.contactPhone,
            seed: teamData.seed,
            color: teamData.colorValue != null ? Color(int.parse(teamData.colorValue!)) : null,
          );
          createdTeams.add(team);
          existingTeamNames.add(teamData.name.toLowerCase());
        } catch (e) {
          skippedTeams.add('${teamData.name} (error: $e)');
        }
      }

      // Import resources
      for (final resourceData in importResult.resources) {
        if (existingResourceNames.contains(resourceData.name.toLowerCase())) {
          skippedResources.add('${resourceData.name} (already exists)');
          continue;
        }

        try {
          final resource = await _resourceRepository.createResource(
            tournamentId: tournamentId,
            name: resourceData.name,
            type: resourceData.type,
            description: resourceData.description,
            capacity: resourceData.capacity,
            location: resourceData.location,
          );
          createdResources.add(resource);
          existingResourceNames.add(resourceData.name.toLowerCase());
        } catch (e) {
          skippedResources.add('${resourceData.name} (error: $e)');
        }
      }

      return ImportSummary(
        teamsCreated: createdTeams.length,
        teamsSkipped: skippedTeams.length,
        resourcesCreated: createdResources.length,
        resourcesSkipped: skippedResources.length,
        skippedTeamDetails: skippedTeams,
        skippedResourceDetails: skippedResources,
        warnings: importResult.warnings,
      );
    } catch (e) {
      throw Exception('Failed to import tournament data: $e');
    }
  }

  /// Apply tiered tournament specific requirements
  List<ImportTeamData> applyTieredTournamentRequirements(List<ImportTeamData> teams) {
    return teams.map((team) {
      // For tiered tournaments, if no seed is provided, default to 10
      if (team.seed == null) {
        return ImportTeamData(
          name: team.name,
          description: team.description,
          contactEmail: team.contactEmail,
          contactPhone: team.contactPhone,
          seed: 10, // Default seed for tiered tournaments
          colorValue: team.colorValue,
        );
      }
      return team;
    }).toList();
  }

  /// Validate import data for specific tournament requirements
  List<String> validateImportData(ImportResult importResult, String format) {
    final warnings = <String>[];
    
    if (format == 'tiered') {
      // Check if teams have seeds (they should after processing)
      for (final team in importResult.teams) {
        if (team.seed == null) {
          warnings.add('Team "${team.name}" will be assigned default seed 10 for tiered tournament');
        }
      }
    }
    
    return warnings;
  }

  /// Save export data to device
  Future<String> saveExportToDevice(String jsonData, String fileName) async {
    try {
      // Use FilePicker to let user choose save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save tournament export file',
        fileName: '$fileName.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonData),
      );
      
      if (result != null) {
        return result;
      } else {
        throw Exception('Save operation was cancelled');
      }
    } catch (e) {
      throw Exception('Failed to save export file: $e');
    }
  }
}

/// Data class for import team information
class ImportTeamData {
  final String name;
  final String? description;
  final String? contactEmail;
  final String? contactPhone;
  final int? seed;
  final String? colorValue;

  ImportTeamData({
    required this.name,
    this.description,
    this.contactEmail,
    this.contactPhone,
    this.seed,
    this.colorValue,
  });
}

/// Data class for import resource information
class ImportResourceData {
  final String name;
  final String type;
  final String? description;
  final int? capacity;
  final String? location;

  ImportResourceData({
    required this.name,
    required this.type,
    this.description,
    this.capacity,
    this.location,
  });
}

/// Data class for export result
class ExportResult {
  final String jsonData;
  final int teamsCount;
  final int resourcesCount;

  ExportResult({
    required this.jsonData,
    required this.teamsCount,
    required this.resourcesCount,
  });

  int get totalCount => teamsCount + resourcesCount;
}

/// Result of parsing import data
class ImportResult {
  final List<ImportTeamData> teams;
  final List<ImportResourceData> resources;
  final List<String> warnings;

  ImportResult({
    required this.teams,
    required this.resources,
    required this.warnings,
  });
}

/// Summary of import operation
class ImportSummary {
  final int teamsCreated;
  final int teamsSkipped;
  final int resourcesCreated;
  final int resourcesSkipped;
  final List<String> skippedTeamDetails;
  final List<String> skippedResourceDetails;
  final List<String> warnings;

  ImportSummary({
    required this.teamsCreated,
    required this.teamsSkipped,
    required this.resourcesCreated,
    required this.resourcesSkipped,
    required this.skippedTeamDetails,
    required this.skippedResourceDetails,
    required this.warnings,
  });

  bool get hasSkippedItems => teamsSkipped > 0 || resourcesSkipped > 0;
  int get totalCreated => teamsCreated + resourcesCreated;
  int get totalSkipped => teamsSkipped + resourcesSkipped;
} 