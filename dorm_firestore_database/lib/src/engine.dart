// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:dorm_framework/dorm_framework.dart';

import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

/// A dORM engine backed by Cloud Firestore.
class Engine implements BaseEngine<Query, OffsetPageRequest> {
  final fs.FirebaseFirestore firestore;
  final String? parentPath;

  const Engine(this.firestore, {this.parentPath});

  @override
  BaseReference<Query, OffsetPageRequest> createReference() =>
      Reference(firestore, parentPath: parentPath);

  @override
  BaseRelationship<Query> createRelationship() => const Relationship();
}
