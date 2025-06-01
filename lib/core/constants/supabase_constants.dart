import 'package:teamapp3/core/config/env.dart';

class SupabaseConstants {
  // Get credentials from environment configuration
  static const String supabaseUrl = Environment.supabaseUrl;
  static const String supabaseAnonKey = Environment.supabaseAnonKey;
  
  // Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String teamLogosBucket = 'team-logos';
  static const String tournamentImagesBucket = 'tournament-images';
  
  // Table names
  static const String usersTable = 'users';
  static const String tournamentsTable = 'tournaments';
  static const String teamsTable = 'teams';
  static const String playersTable = 'players';
  static const String gamesTable = 'games';
  static const String standingsTable = 'standings';
  static const String tournamentAdminsTable = 'tournament_admins';
  static const String categoriesTable = 'categories';
  static const String resourcesTable = 'resources';
  static const String announcementsTable = 'announcements';
} 