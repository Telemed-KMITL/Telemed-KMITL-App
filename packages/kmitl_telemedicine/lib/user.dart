import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'date_time_converter.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole { patient, doctor, nurse, admin, unknown }

@freezed
class User with _$User {
  const factory User({
    required String firstName,
    required String lastName,
    @JsonKey(unknownEnumValue: UserRole.unknown) required UserRole role,
    String? HN,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
