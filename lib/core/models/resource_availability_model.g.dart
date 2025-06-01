// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_availability_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResourceAvailabilityModel _$ResourceAvailabilityModelFromJson(
        Map<String, dynamic> json) =>
    ResourceAvailabilityModel(
      id: json['id'] as String,
      resourceId: json['resource_id'] as String,
      dayOfWeek: (json['day_of_week'] as num?)?.toInt(),
      specificDate: json['specific_date'] == null
          ? null
          : DateTime.parse(json['specific_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ResourceAvailabilityModelToJson(
        ResourceAvailabilityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'resource_id': instance.resourceId,
      'day_of_week': instance.dayOfWeek,
      'specific_date': instance.specificDate?.toIso8601String(),
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'is_available': instance.isAvailable,
      'created_at': instance.createdAt.toIso8601String(),
    };
