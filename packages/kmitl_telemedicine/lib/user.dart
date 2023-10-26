import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'date_time_converter.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole { patient, doctor, nurse, admin, unknown }

enum UserStatus { active, inactive, unknown }

@freezed
class User with _$User {
  const User._();
  const factory User({
    required String firstName,
    required String lastName,
    @JsonKey(unknownEnumValue: UserRole.unknown) required UserRole role,
    @JsonKey(unknownEnumValue: UserStatus.unknown) required UserStatus status,
    @JsonKey(name: "HN") required String? hn,
    @DateTimeConverter() required DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  String getDisplayName() => "$firstName $lastName";
}
