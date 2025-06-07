import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamapp3/features/tournaments/data/models/category_model.dart';

class CategoryRepository {

  CategoryRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;
  final SupabaseClient _supabaseClient;

  Future<CategoryModel> createCategory({
    required String tournamentId,
    required String name,
    String? description,
    int? maxTeams,
    int minTeams = 2,
    int displayOrder = 0,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not authenticated');
    }

    final insertData = {
      'tournament_id': tournamentId,
      'name': name,
      'description': description,
      'max_teams': maxTeams,
      'min_teams': minTeams,
      'display_order': displayOrder,
    };

    final data = await _supabaseClient.from('tournament_categories').insert(insertData).select().single();
    return CategoryModel.fromJson(data);
  }

  Future<List<CategoryModel>> getTournamentCategories(String tournamentId) async {
    final data = await _supabaseClient
        .from('tournament_categories')
        .select()
        .eq('tournament_id', tournamentId)
        .eq('is_active', true)
        .order('display_order', ascending: true);

    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    final data = await _supabaseClient
        .from('tournament_categories')
        .select()
        .eq('id', categoryId)
        .maybeSingle();

    if (data == null) return null;
    return CategoryModel.fromJson(data);
  }

  Future<CategoryModel> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    int? maxTeams,
    int? minTeams,
    bool? isActive,
    int? displayOrder,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (maxTeams != null) updateData['max_teams'] = maxTeams;
    if (minTeams != null) updateData['min_teams'] = minTeams;
    if (isActive != null) updateData['is_active'] = isActive;
    if (displayOrder != null) updateData['display_order'] = displayOrder;

    final data = await _supabaseClient
        .from('tournament_categories')
        .update(updateData)
        .eq('id', categoryId)
        .select()
        .single();

    return CategoryModel.fromJson(data);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _supabaseClient
        .from('tournament_categories')
        .delete()
        .eq('id', categoryId);
  }

  Future<void> reorderCategories(List<Map<String, dynamic>> categoryOrders) async {
    for (final item in categoryOrders) {
      await _supabaseClient
          .from('tournament_categories')
          .update({'display_order': item['displayOrder'] as int})
          .eq('id', item['id'] as String);
    }
  }

  Future<List<CategoryModel>> createDefaultCategories(String tournamentId) async {
    final defaultCategories = <Map<String, dynamic>>[
      {
        'tournament_id': tournamentId,
        'name': 'Open',
        'description': 'Open category for all teams',
        'display_order': 1,
      },
    ];

    final data = await _supabaseClient
        .from('tournament_categories')
        .insert(defaultCategories)
        .select();

    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }
} 