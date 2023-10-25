// https://stackoverflow.com/questions/46573804/firestore-query-documents-startswith-a-string
// ignore_for_file: unnecessary_this

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomFilters {
  static Filter startsWith(Object field, String prefix) => Filter.and(
        Filter(field, isGreaterThanOrEqualTo: prefix),
        Filter(field, isLessThan: "$prefix\uf8ff"),
      );
}
