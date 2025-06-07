import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:teamapp3/core/models/resource_availability_model.dart';

class ResourceAvailabilityRepository {

  ResourceAvailabilityRepository({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;
  final SupabaseClient _supabaseClient;

  /// Create recurring availability (weekly schedule)
  Future<ResourceAvailabilityModel> createRecurringAvailability({
    required String resourceId,
    required int dayOfWeek, // 0=Sunday, 1=Monday, etc.
    required String startTime, // Format: "HH:MM"
    required String endTime, // Format: "HH:MM"
    bool isAvailable = true,
  }) async {
    final insertData = {
      'resource_id': resourceId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
    };

    final data = await _supabaseClient
        .from('resource_availability')
        .insert(insertData)
        .select()
        .single();

    return ResourceAvailabilityModel.fromJson(data);
  }

  /// Create specific date availability
  Future<ResourceAvailabilityModel> createSpecificDateAvailability({
    required String resourceId,
    required DateTime specificDate,
    required String startTime, // Format: "HH:MM"
    required String endTime, // Format: "HH:MM"
    bool isAvailable = true,
  }) async {
    final insertData = {
      'resource_id': resourceId,
      'specific_date': specificDate.toIso8601String().split('T')[0], // Date only
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
    };

    final data = await _supabaseClient
        .from('resource_availability')
        .insert(insertData)
        .select()
        .single();

    return ResourceAvailabilityModel.fromJson(data);
  }

  /// Get all availability for a specific resource
  Future<List<ResourceAvailabilityModel>> getResourceAvailability(String resourceId) async {
    final data = await _supabaseClient
        .from('resource_availability')
        .select()
        .eq('resource_id', resourceId)
        .order('day_of_week', ascending: true)
        .order('specific_date', ascending: true)
        .order('start_time', ascending: true);

    return data.map((json) => ResourceAvailabilityModel.fromJson(json)).toList();
  }

  /// Get recurring availability (weekly schedule) for a resource
  Future<List<ResourceAvailabilityModel>> getRecurringAvailability(String resourceId) async {
    final data = await _supabaseClient
        .from('resource_availability')
        .select()
        .eq('resource_id', resourceId)
        .not('day_of_week', 'is', null)
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);

    return data.map((json) => ResourceAvailabilityModel.fromJson(json)).toList();
  }

  /// Get specific date availability for a resource
  Future<List<ResourceAvailabilityModel>> getSpecificDateAvailability(String resourceId) async {
    final data = await _supabaseClient
        .from('resource_availability')
        .select()
        .eq('resource_id', resourceId)
        .not('specific_date', 'is', null)
        .order('specific_date', ascending: true)
        .order('start_time', ascending: true);

    return data.map((json) => ResourceAvailabilityModel.fromJson(json)).toList();
  }

  /// Get availability for a specific date range
  Future<List<ResourceAvailabilityModel>> getAvailabilityForDateRange({
    required String resourceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final data = await _supabaseClient
        .from('resource_availability')
        .select()
        .eq('resource_id', resourceId)
        .or(
          'specific_date.gte.${startDate.toIso8601String().split('T')[0]},'
          'specific_date.lte.${endDate.toIso8601String().split('T')[0]},'
          'day_of_week.not.is.null'
        )
        .order('specific_date', ascending: true)
        .order('day_of_week', ascending: true)
        .order('start_time', ascending: true);

    return data.map((json) => ResourceAvailabilityModel.fromJson(json)).toList();
  }

  /// Update availability
  Future<ResourceAvailabilityModel> updateAvailability({
    required String availabilityId,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) async {
    final updateData = <String, dynamic>{};
    
    if (startTime != null) updateData['start_time'] = startTime;
    if (endTime != null) updateData['end_time'] = endTime;
    if (isAvailable != null) updateData['is_available'] = isAvailable;

    final data = await _supabaseClient
        .from('resource_availability')
        .update(updateData)
        .eq('id', availabilityId)
        .select()
        .single();

    return ResourceAvailabilityModel.fromJson(data);
  }

  /// Delete availability
  Future<void> deleteAvailability(String availabilityId) async {
    await _supabaseClient
        .from('resource_availability')
        .delete()
        .eq('id', availabilityId);
  }

  /// Delete all availability for a resource
  Future<void> deleteAllResourceAvailability(String resourceId) async {
    await _supabaseClient
        .from('resource_availability')
        .delete()
        .eq('resource_id', resourceId);
  }

  /// Check if a resource is available at a specific time
  Future<bool> isResourceAvailable({
    required String resourceId,
    required DateTime dateTime,
    String? excludeAvailabilityId,
  }) async {
    final date = dateTime.toIso8601String().split('T')[0];
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    final dayOfWeek = dateTime.weekday % 7; // Convert to 0=Sunday format

    // Check for specific date availability first
    var query = _supabaseClient
        .from('resource_availability')
        .select()
        .eq('resource_id', resourceId)
        .eq('specific_date', date)
        .lte('start_time', time)
        .gte('end_time', time)
        .eq('is_available', true);

    if (excludeAvailabilityId != null) {
      query = query.neq('id', excludeAvailabilityId);
    }

    final specificDateResult = await query;

    if (specificDateResult.isNotEmpty) {
      return true;
    }

    // Check for recurring availability
    query = _supabaseClient
        .from('resource_availability')
        .select()
        .eq('resource_id', resourceId)
        .eq('day_of_week', dayOfWeek)
        .lte('start_time', time)
        .gte('end_time', time)
        .eq('is_available', true);

    if (excludeAvailabilityId != null) {
      query = query.neq('id', excludeAvailabilityId);
    }

    final recurringResult = await query;

    return recurringResult.isNotEmpty;
  }

  /// Get availability summary for a resource
  Future<Map<String, dynamic>> getAvailabilitySummary(String resourceId) async {
    final data = await _supabaseClient
        .from('resource_availability')
        .select('day_of_week, specific_date, is_available')
        .eq('resource_id', resourceId);

    var recurringSlots = 0;
    var specificDateSlots = 0;
    var unavailableSlots = 0;

    for (final item in data) {
      if (item['day_of_week'] != null) {
        recurringSlots++;
      } else {
        specificDateSlots++;
      }
      
      if (item['is_available'] == false) {
        unavailableSlots++;
      }
    }

    return {
      'total_slots': data.length,
      'recurring_slots': recurringSlots,
      'specific_date_slots': specificDateSlots,
      'unavailable_slots': unavailableSlots,
      'available_slots': data.length - unavailableSlots,
    };
  }
} 