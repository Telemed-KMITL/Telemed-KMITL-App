import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'date_time_converter.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole {
  patient,
  staff,
  nurse,
  admin,
}

@freezed
class User with _$User {
  const factory User({
    required String name,
    required UserRole role,
    // PatientData patientData,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
