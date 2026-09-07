import 'package:dorm_framework/dorm_framework.dart';

import 'query.dart';

/// Describes one HTTP method and its relative path.
class HttpEndpoint {
  final String method;
  final String path;

  const HttpEndpoint(this.method, this.path);
}

/// Controls where an identity is written for an HTTP operation.
enum HttpIdentityLocation { path, body, pathAndBody }

/// Describes the endpoints for one dORM entity.
class HttpResourceMapping {
  final String path;
  final String? itemPath;
  final HttpEndpoint create;
  final HttpEndpoint? createAll;
  final HttpEndpoint update;
  final HttpEndpoint? updateAll;
  final HttpEndpoint delete;
  final HttpEndpoint? deleteKeys;
  final HttpEndpoint deleteAll;
  final HttpEndpoint keys;
  final HttpEndpoint purge;
  final HttpIdentityLocation identityLocation;

  /// Creates a REST-shaped resource mapping.
  ///
  /// The `{id}` placeholder in an endpoint path is replaced by the identity
  /// encoder configured in [HttpMapping].
  HttpResourceMapping({
    required this.path,
    this.itemPath,
    this.createAll,
    this.updateAll,
    this.deleteKeys,
    HttpEndpoint? create,
    HttpEndpoint? update,
    HttpEndpoint? delete,
    HttpEndpoint? deleteAll,
    HttpEndpoint? keys,
    HttpEndpoint? purge,
    this.identityLocation = HttpIdentityLocation.pathAndBody,
  }) : create = create ?? HttpEndpoint('POST', path),
       update = update ?? HttpEndpoint('PUT', itemPath ?? '$path/{id}'),
       delete = delete ?? HttpEndpoint('DELETE', itemPath ?? '$path/{id}'),
       deleteAll = deleteAll ?? HttpEndpoint('DELETE', path),
       keys = keys ?? HttpEndpoint('GET', path),
       purge = purge ?? HttpEndpoint('DELETE', path);

  HttpEndpoint get collection => HttpEndpoint('GET', path);

  HttpEndpoint get item => HttpEndpoint('GET', itemPath ?? '$path/{id}');
}

/// Converts dORM query conditions to HTTP query parameters.
abstract interface class HttpQueryCodec {
  Map<String, String> encode(Query query, EntitySchema schema);
}

/// The default query parameter convention for REST-shaped APIs.
class DefaultHttpQueryCodec implements HttpQueryCodec {
  const DefaultHttpQueryCodec();

  @override
  Map<String, String> encode(Query query, EntitySchema schema) {
    final Map<String, String> result = {};
    for (final QueryCondition condition in query.conditions) {
      switch (condition) {
        case ValueCondition(:final key, :final value):
          result[key] = _encodeValue(value);
        case TextCondition(:final key, :final prefix):
          result['${key}__startsWith'] = prefix;
        case DateCondition(:final key, :final date, :final unit):
          result['${key}__gte'] = _startOf(date, unit).toIso8601String();
          result['${key}__lte'] = _endOf(date, unit).toIso8601String();
        case RangeCondition(:final key, :final from, :final to, :final unit):
          if (from != null) {
            result['${key}__gte'] = _encodeRangeBound(from, unit, lower: true);
          }
          if (to != null) {
            result['${key}__lte'] = _encodeRangeBound(to, unit, lower: false);
          }
        case SortCondition(:final key, :final ascending):
          final String value = ascending ? key : '-$key';
          final String? current = result['sort'];
          result['sort'] = current == null ? value : '$current,$value';
        case LimitCondition(:final count):
          result['limit'] = '$count';
        case OffsetCondition(:final count):
          result['offset'] = '$count';
      }
    }
    return result;
  }

  String _encodeRangeBound(
    Object value,
    DateFilterUnit? unit, {
    required bool lower,
  }) {
    if (value is DateTime && unit != null) {
      return (lower ? _startOf(value, unit) : _endOf(value, unit))
          .toIso8601String();
    }
    return _encodeValue(value);
  }

  String _encodeValue(Object? value) {
    if (value is DateTime) return value.toIso8601String();
    if (value is bool) return value.toString();
    return '$value';
  }
}

DateTime _startOf(DateTime value, DateFilterUnit unit) {
  return switch (unit) {
    DateFilterUnit.year => DateTime(value.year),
    DateFilterUnit.month => DateTime(value.year, value.month),
    DateFilterUnit.day => DateTime(value.year, value.month, value.day),
    DateFilterUnit.hour => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
    ),
    DateFilterUnit.minute => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    ),
    DateFilterUnit.second => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    ),
    DateFilterUnit.milliseconds => value,
  };
}

DateTime _endOf(DateTime value, DateFilterUnit unit) {
  return switch (unit) {
    DateFilterUnit.year => DateTime(
      value.year + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.month => DateTime(
      value.year,
      value.month + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.day => DateTime(
      value.year,
      value.month,
      value.day + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.hour => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.minute => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.second => DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second + 1,
    ).subtract(const Duration(milliseconds: 1)),
    DateFilterUnit.milliseconds => value,
  };
}

/// Decodes standard JSON response shapes and configurable `data` envelopes.
class HttpJsonCodec {
  final Object? Function(Object? body) single;
  final List<Object?> Function(Object? body) list;
  final List<Object?> Function(Object? body) keys;

  const HttpJsonCodec({
    this.single = _single,
    this.list = _list,
    this.keys = _keys,
  });

  /// Creates a codec that unwraps [key] before decoding the response.
  factory HttpJsonCodec.envelope({String key = 'data'}) {
    Object? unwrap(Object? body) {
      if (body is Map<String, Object?>) return body[key];
      if (body is Map) return body[key];
      return null;
    }

    return HttpJsonCodec(
      single: unwrap,
      list: (body) => _asList(unwrap(body)),
      keys: (body) => _asList(unwrap(body)),
    );
  }

  static Object? _single(Object? body) => body;

  static List<Object?> _list(Object? body) => _asList(body);

  static List<Object?> _keys(Object? body) => _asList(body);
}

List<Object?> _asList(Object? body) {
  if (body is List) return body.cast<Object?>();
  throw const FormatException('Expected a JSON list.');
}

/// Configures how entity schemas are represented by an HTTP API.
class HttpMapping {
  final HttpResourceMapping Function(EntitySchema schema) resource;
  final HttpQueryCodec queryCodec;
  final HttpJsonCodec jsonCodec;
  final String Function(Object identity) encodeIdentity;

  const HttpMapping({
    required this.resource,
    this.queryCodec = const DefaultHttpQueryCodec(),
    this.jsonCodec = const HttpJsonCodec(),
    this.encodeIdentity = _defaultIdentity,
  });

  /// Creates a mapping from table names to REST resources.
  factory HttpMapping.byTableName(
    Map<String, HttpResourceMapping> resources, {
    HttpQueryCodec queryCodec = const DefaultHttpQueryCodec(),
    HttpJsonCodec jsonCodec = const HttpJsonCodec(),
    String Function(Object identity) encodeIdentity = _defaultIdentity,
  }) {
    return HttpMapping(
      resource: (schema) {
        final HttpResourceMapping? value = resources[schema.tableName];
        if (value == null) {
          throw ArgumentError.value(
            schema.tableName,
            'schema.tableName',
            'No HTTP resource mapping was configured.',
          );
        }
        return value;
      },
      queryCodec: queryCodec,
      jsonCodec: jsonCodec,
      encodeIdentity: encodeIdentity,
    );
  }
}

String _defaultIdentity(Object identity) => Uri.encodeComponent('$identity');
