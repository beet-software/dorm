import 'package:dorm_framework/dorm_framework.dart';
import 'package:http/http.dart' as http;

import 'mapping.dart';
import 'query.dart';
import 'reference.dart';
import 'relationship.dart';

/// An HTTP/JSON engine for REST-shaped APIs.
class Engine implements BaseEngine<Query> {
  final http.Client client;
  final Uri baseUri;
  final HttpMapping mapping;
  final Map<String, String> headers;

  /// Creates an engine using an application-owned HTTP [client].
  const Engine({
    required this.client,
    required this.baseUri,
    required this.mapping,
    this.headers = const {},
  });

  @override
  BaseReference<Query> createReference() => Reference(
    client: client,
    baseUri: baseUri,
    mapping: mapping,
    headers: headers,
  );

  @override
  BaseRelationship<Query> createRelationship() => const Relationship();
}
