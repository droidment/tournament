import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamapp3/core/constants/supabase_constants.dart';

class SupabaseService {

  SupabaseService._();
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
  }

  // User authentication getters
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get currentUserId => currentUser?.id;

  // Auth stream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Database operations
  PostgrestQueryBuilder from(String table) => client.from(table);

  // Storage operations
  SupabaseStorageClient get storage => client.storage;

  // Realtime operations
  RealtimeClient get realtime => client.realtime;
} 