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
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      homeAddress: json['home_address'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      bloodGroup: json['blood_group'] as String?,
      genotype: json['genotype'] as String?,
      allergies: json['allergies'] as String?,
      medicalConditions: json['medical_conditions'] as String?,
      admissionDate: json['admission_date'] == null
          ? null
          : DateTime.parse(json['admission_date'] as String),
      status: json['status'] as String?,
    );

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
      'id': instance.id,
      'enrollment_number': instance.enrollmentNumber,
      'full_name': instance.fullName,
      'grade': instance.grade,
      'parent_id': instance.parentId,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'gender': instance.gender,
      'profile_picture_url': instance.profilePictureUrl,
      'home_address': instance.homeAddress,
      'emergency_contact_name': instance.emergencyContactName,
      'emergency_contact_phone': instance.emergencyContactPhone,
      'blood_group': instance.bloodGroup,
      'genotype': instance.genotype,
      'allergies': instance.allergies,
      'medical_conditions': instance.medicalConditions,
      'admission_date': instance.admissionDate?.toIso8601String(),
      'status': instance.status,
    };
