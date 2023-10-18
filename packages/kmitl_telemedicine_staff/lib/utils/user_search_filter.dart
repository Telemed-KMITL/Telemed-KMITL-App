import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kmitl_telemedicine/kmitl_telemedicine.dart';
import 'package:kmitl_telemedicine/utils/date_time_extension.dart';

enum UserFilterCondition {
  orderBy,
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
}

enum UserSortDirection {
  ascending,
  descending,
}

class UserSearchFilter {
  static final Map<String, Type> _userFieldDefinitions = {
    "id": String,
    "firstName": String,
    "lastName": String,
    "role": UserRole,
    "status": UserStatus,
    "HN": String,
    "updatedAt": DateTime,
  };

  static Iterable<String> get fieldNames => _userFieldDefinitions.keys;
  static final Map<UserFilterCondition, String> conditionNames = {
    UserFilterCondition.orderBy: "OrderBy",
    UserFilterCondition.isEqualTo: "=",
    UserFilterCondition.isNotEqualTo: "≠",
    UserFilterCondition.isLessThan: "<",
    UserFilterCondition.isLessThanOrEqualTo: "≤",
    UserFilterCondition.isGreaterThan: ">",
    UserFilterCondition.isGreaterThanOrEqualTo: "≥",
  };

  static Type getValueType(String fieldName, UserFilterCondition condition) {
    return condition == UserFilterCondition.orderBy
        ? UserSortDirection
        : _userFieldDefinitions[fieldName]!;
  }

  UserSearchFilter(this.fieldName, this.condition, this.value) {
    assert(_userFieldDefinitions.containsKey(fieldName));
    assert(getValueType(fieldName, condition) == value.runtimeType);
    field = fieldName == "id" ? FieldPath.documentId : FieldPath([fieldName]);
  }

  final String fieldName;
  late final Object field;
  final UserFilterCondition condition;
  final dynamic value;

  Query<User> appendQuery(Query<User> query) {
    return switch (condition) {
      UserFilterCondition.orderBy =>
        query.orderBy(field, descending: value == UserSortDirection.descending),
      UserFilterCondition.isEqualTo =>
        query.where(field, isEqualTo: _firestoreValue),
      UserFilterCondition.isNotEqualTo =>
        query.where(field, isNotEqualTo: _firestoreValue),
      UserFilterCondition.isLessThan =>
        query.where(field, isLessThan: _firestoreValue),
      UserFilterCondition.isLessThanOrEqualTo =>
        query.where(field, isLessThanOrEqualTo: _firestoreValue),
      UserFilterCondition.isGreaterThan =>
        query.where(field, isGreaterThan: _firestoreValue),
      UserFilterCondition.isGreaterThanOrEqualTo =>
        query.where(field, isGreaterThanOrEqualTo: _firestoreValue),
    };
  }

  @override
  String toString() => condition == UserFilterCondition.orderBy
      ? "${conditionNames[condition]}: $fieldName (${_valueToString()})"
      : "$fieldName ${conditionNames[condition]} ${_valueToString()}";

  String _valueToString() {
    return switch (value) {
      (DateTime t) => t.toLongTimestampString(),
      (Enum e) => e.name,
      (String s) => "\"$s\"",
      _ => value.toString(),
    };
  }

  dynamic get _firestoreValue {
    return switch (value) {
      (Enum e) => e.name,
      (DateTime e) => Timestamp.fromDate(e),
      _ => value,
    };
  }
}
