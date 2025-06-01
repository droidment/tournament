import 'package:json_annotation/json_annotation.dart';

part 'resource_availability_model.g.dart';

@JsonSerializable()
class ResourceAvailabilityModel {
  final String id;
  @JsonKey(name: 'resource_id')
  final String resourceId;
  @JsonKey(name: 'day_of_week')
  final int? dayOfWeek; // 0=Sunday, 1=Monday, etc.
  @JsonKey(name: 'specific_date')
  final DateTime? specificDate;
  @JsonKey(name: 'start_time')
  final String startTime; // TIME format from database
  @JsonKey(name: 'end_time')
  final String endTime; // TIME format from database
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const ResourceAvailabilityModel({
    required this.id,
    required this.resourceId,
    this.dayOfWeek,
    this.specificDate,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    required this.createdAt,
  });

  factory ResourceAvailabilityModel.fromJson(Map<String, dynamic> json) =>
      _$ResourceAvailabilityModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceAvailabilityModelToJson(this);

  ResourceAvailabilityModel copyWith({
    String? id,
    String? resourceId,
    int? dayOfWeek,
    DateTime? specificDate,
    String? startTime,
    String? endTime,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return ResourceAvailabilityModel(
      id: id ?? this.id,
      resourceId: resourceId ?? this.resourceId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      specificDate: specificDate ?? this.specificDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  bool get isRecurring => dayOfWeek != null;
  bool get isSpecificDate => specificDate != null;

  String get dayName {
    if (dayOfWeek == null) return '';
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek!];
  }

  String get fullDayName {
    if (dayOfWeek == null) return '';
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek!];
  }

  String get displayDate {
    if (specificDate != null) {
      return '${specificDate!.day}/${specificDate!.month}/${specificDate!.year}';
    }
    return fullDayName;
  }

  String get timeRange => '$startTime - $endTime';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceAvailabilityModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ResourceAvailabilityModel{id: $id, resourceId: $resourceId, dayOfWeek: $dayOfWeek, specificDate: $specificDate, startTime: $startTime, endTime: $endTime, isAvailable: $isAvailable}';
  }
} 