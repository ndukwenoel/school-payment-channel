// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

School _$SchoolFromJson(Map<String, dynamic> json) => School(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String?,
      contactEmail: json['contact_email'] as String?,
      logoUrl: json['logo_url'] as String?,
    );

Map<String, dynamic> _$SchoolToJson(School instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'contact_email': instance.contactEmail,
      'logo_url': instance.logoUrl,
    };

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
      id: (json['id'] as num).toInt(),
      enrollmentNumber: json['enrollment_number'] as String,
      fullName: json['full_name'] as String,
      grade: json['grade'] as String,
      parentId: (json['parent_id'] as num).toInt(),
    );

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
      'id': instance.id,
      'enrollment_number': instance.enrollmentNumber,
      'full_name': instance.fullName,
      'grade': instance.grade,
      'parent_id': instance.parentId,
    };
