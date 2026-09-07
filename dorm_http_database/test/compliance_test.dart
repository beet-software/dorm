import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_http_database/dorm_http_database.dart';
import 'package:dorm_test/dorm_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _HttpSession implements EngineTestSession<Query> {
  final _HttpBackend backend;
  final http.Client client;

  _HttpSession(this.backend, this.client)
    : engine = Engine(
        client: client,
        baseUri: Uri.parse('https://example.test/'),
        mapping: HttpMapping.byTableName({
          for (final String table in [
            'dorm_compliance_items',
            'dorm_compliance_parents',
            'dorm_compliance_profiles',
            'dorm_compliance_children',
            'dorm_compliance_links',
            'dorm_compliance_composites',
          ])
            table: HttpResourceMapping(
              path: table,
              createAll: HttpEndpoint('POST', '$table/batch'),
              updateAll: HttpEndpoint('PUT', '$table/batch'),
              deleteKeys: HttpEndpoint('POST', '$table/delete'),
            ),
        },
        encodeIdentity: (identity) => switch (identity) {
          CompositeKey(:final values) => values.join('|'),
          _ => '$identity',
        },
        ),
      );

  @override
  final Engine engine;

  @override
  final EngineCapabilities capabilities = const EngineCapabilities(
    compositeIdentities: true,
    negativeLimits: true,
  );

  @override
  Future<void> reset() async => backend.tables.clear();

  @override
  Future<void> close() async => client.close();
}

class _HttpAdapter implements EngineTestAdapter<Query> {
  @override
  String get name => 'HTTP';

  @override
  Future<EngineTestSession<Query>> open() async {
    final _HttpBackend backend = _HttpBackend();
    final MockClient client = MockClient(backend.handle);
    return _HttpSession(backend, client);
  }
}

class _HttpBackend {
  final Map<String, List<Map<String, Object?>>> tables = {};

  Future<http.Response> handle(http.BaseRequest request) async {
    final List<String> segments = request.url.pathSegments;
    if (segments.isEmpty) return _response(404, {'error': 'missing path'});
    final String table = segments.first;
    final List<Map<String, Object?>> rows = tables.putIfAbsent(
      table,
      () => <Map<String, Object?>>[],
    );
    final Object? body = request is http.Request && request.body.isNotEmpty
        ? jsonDecode(request.body)
        : null;

    if (segments.length > 1 && segments[1] == 'batch') {
      final List<Object?> values = (body as List).cast<Object?>();
      if (request.method == 'POST') {
        for (final Object? value in values) _replace(rows, _map(value));
        return _response(200, values);
      }
      if (request.method == 'PUT') {
        for (final Object? value in values) _replace(rows, _map(value));
        return _response(204, null);
      }
    }

    if (segments.length > 1 && segments[1] == 'delete') {
      for (final Object? value in (body as List).cast<Object?>()) {
        rows.removeWhere((row) => _sameIdentity(table, row, value));
      }
      return _response(204, null);
    }

    if (segments.length == 1) {
      if (request.method == 'GET') {
        return _response(200, _query(rows, request.url.queryParameters));
      }
      if (request.method == 'POST') {
        _replace(rows, _map(body));
        return _response(200, body);
      }
      if (request.method == 'DELETE') {
        if (request.url.queryParameters.isEmpty) {
          rows.clear();
        } else {
          rows.removeWhere((row) => _matches(row, request.url.queryParameters));
        }
        return _response(204, null);
      }
    }

    if (segments.length == 2) {
      final String id = segments[1];
      final int index = rows.indexWhere((row) => _sameIdentity(table, row, id));
      if (request.method == 'GET') {
        return index < 0
            ? _response(404, {'error': 'missing'})
            : _response(200, rows[index]);
      }
      if (request.method == 'PUT') {
        _replace(rows, _map(body));
        return _response(204, null);
      }
      if (request.method == 'DELETE') {
        if (index >= 0) rows.removeAt(index);
        return _response(204, null);
      }
    }
    return _response(405, {'error': 'unsupported'});
  }

  List<Map<String, Object?>> _query(
    List<Map<String, Object?>> input,
    Map<String, String> parameters,
  ) {
    final List<Map<String, Object?>> result = input
        .where((row) => _matches(row, parameters))
        .toList();
    final String? sort = parameters['sort'];
    if (sort != null) {
      result.sort((left, right) => '${left[sort]}'.compareTo('${right[sort]}'));
    }
    final int? limit = int.tryParse(parameters['limit'] ?? '');
    if (limit == null || limit == 0) return result;
    return limit > 0
        ? result.take(limit).toList()
        : result.reversed.take(limit.abs()).toList();
  }

  bool _matches(Map<String, Object?> row, Map<String, String> parameters) {
    for (final MapEntry<String, String> entry in parameters.entries) {
      final String key = entry.key;
      if (key == 'sort' || key == 'limit') continue;
      if (key.endsWith('__startsWith')) {
        final String field = key.substring(0, key.length - 12);
        if (!'${row[field]}'.startsWith(entry.value)) return false;
      } else if (key.endsWith('__gte') || key.endsWith('__lte')) {
        final bool lower = key.endsWith('__gte');
        final String field = key.substring(0, key.length - 5);
        final double? actual = double.tryParse('${row[field]}');
        final double? expected = double.tryParse(entry.value);
        if (actual != null && expected != null) {
          if (lower ? actual < expected : actual > expected) return false;
        }
      } else if ('${row[key]}' != entry.value) {
        return false;
      }
    }
    return true;
  }

  void _replace(List<Map<String, Object?>> rows, Map<String, Object?> value) {
    final int index = rows.indexWhere((row) => row['id'] == value['id']);
    if (index < 0) {
      rows.add(value);
    } else {
      rows[index] = value;
    }
  }

  bool _sameIdentity(String table, Map<String, Object?> row, Object? id) {
    if (table == 'dorm_compliance_composites') {
      if (id is List && id.length == 2) {
        return row['tenant'] == id[0] && row['number'] == id[1];
      }
      final List<String> values = '$id'.split('|');
      return values.length == 2 &&
          row['tenant'] == values[0] &&
          '${row['number']}' == values[1];
    }
    return row['id'] == id;
  }

  Map<String, Object?> _map(Object? value) => (value as Map).map(
    (key, value) => MapEntry('$key', value),
  );

  http.Response _response(int status, Object? body) => http.Response(
    body == null ? '' : jsonEncode(body),
    status,
    headers: const {'content-type': 'application/json'},
  );
}

void main() {
  defineEngineComplianceTests(_HttpAdapter());
}
