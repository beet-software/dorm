import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'error.dart';
import 'mapping.dart';
import 'query.dart';

class Reference implements BaseReference<Query> {
  final http.Client client;
  final Uri baseUri;
  final HttpMapping mapping;
  final Map<String, String> headers;

  const Reference({
    required this.client,
    required this.baseUri,
    required this.mapping,
    required this.headers,
  });

  HttpResourceMapping _resource(EntitySchema schema) => mapping.resource(schema);

  Uri _uri(String path, {Map<String, String> query = const {}}) {
    final String relative = path.startsWith('/') ? path.substring(1) : path;
    return baseUri.resolve(relative).replace(
      queryParameters: query.isEmpty ? null : query,
    );
  }

  String _path(String path, Object? id) {
    if (id == null) return path;
    return path.replaceAll('{id}', mapping.encodeIdentity(id));
  }

  Future<http.Response> _request(
    HttpEndpoint endpoint,
    EntitySchema schema, {
    Object? id,
    Map<String, String> query = const {},
    Object? body,
  }) async {
    final Uri uri = _uri(_path(endpoint.path, id), query: query);
    final http.Request request = http.Request(endpoint.method, uri)
      ..headers.addAll(headers);
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response = await http.Response.fromStream(
      await client.send(request),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpDatabaseException(
        statusCode: response.statusCode,
        method: endpoint.method,
        uri: uri,
        body: response.body,
      );
    }
    return response;
  }

  Object? _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Map<String, Object?> _map(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected a JSON object.');
    }
    return value.map((key, value) => MapEntry('$key', value));
  }

  I _decodeIdentity<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Map<String, Object?> data,
  ) {
    return entity.primaryKeyCodec.decode(
      entity.schema.primaryKeys.map((field) => data[field.columnName]),
    );
  }

  Model _decodeModel<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Object? value, {
    I? id,
  }) {
    final Map<String, Object?> data = _map(value);
    return entity.fromJson(id ?? _decodeIdentity(entity, data), data);
  }

  List<Model> _decodeModels<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Object? value,
  ) {
    final Object? decoded = mapping.jsonCodec.list(value);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON list.');
    }
    return decoded
        .map((item) => _decodeModel(entity, item))
        .toList(growable: false);
  }

  Map<String, Object?> _bodyForModel<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
    HttpResourceMapping resource,
  ) {
    final Map<String, Object?> data = {...entity.toJson(model)};
    if (resource.identityLocation == HttpIdentityLocation.path) return data;
    final List<Object?> values = entity.primaryKeyCodec.encode(
      entity.identify(model),
    );
    if (values.length != entity.schema.primaryKeys.length) {
      throw StateError('Primary-key codec returned an invalid value count.');
    }
    for (int index = 0; index < values.length; index++) {
      data[entity.schema.primaryKeys[index].columnName] = values[index];
    }
    return data;
  }

  ResolvedCreation<Data, I> _resolveCreation<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) {
    return switch (creation.identity) {
      AutoIdentity<I>() => _resolveAuto(entity, creation),
      ExplicitIdentity<I>(:final value) => () {
        _validateIdentity(entity, value);
        return ResolvedCreation(
          dependency: creation.dependency,
          data: creation.data,
          id: value,
          wasGenerated: false,
        );
      }(),
    };
  }

  ResolvedCreation<Data, I> _resolveAuto<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) {
    if (entity.schema.isCompositePrimaryKey ||
        !entity.supportsAutomaticIdentity) {
      throw UnsupportedError(
        'HTTP creation requires an explicit identity for this entity.',
      );
    }
    return ResolvedCreation(
      dependency: creation.dependency,
      data: creation.data,
      id: const Uuid().v4() as I,
      wasGenerated: true,
    );
  }

  void _validateIdentity<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    final List<Object?> values;
    try {
      values = entity.primaryKeyCodec.encode(id);
    } catch (_) {
      throw ArgumentError.value(
        id,
        'identity',
        'Identity cannot be encoded for this schema.',
      );
    }
    if (values.length != entity.schema.primaryKeys.length) {
      throw ArgumentError.value(
        id,
        'identity',
        'Identity has ${values.length} values, but the schema requires '
            '${entity.schema.primaryKeys.length}.',
      );
    }
  }

  Map<String, String> _queryParameters<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) {
    final Query query = filter.accept(Query(schema: entity.schema));
    return mapping.queryCodec.encode(query, entity.schema);
  }

  @override
  Future<Model?> peek<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async {
    final HttpResourceMapping resource = _resource(entity.schema);
    final http.Response response;
    try {
      response = await _request(resource.item, entity.schema, id: id);
    } on HttpDatabaseException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
    final Object? body = _decode(response);
    if (body == null) return null;
    return _decodeModel<Data, Model, I>(
      entity,
      mapping.jsonCodec.single(body),
      id: id,
    );
  }

  @override
  Future<List<Model>> peekAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) async {
    final HttpResourceMapping resource = _resource(entity.schema);
    final http.Response response = await _request(
      resource.collection,
      entity.schema,
      query: _queryParameters(entity, filter),
    );
    return _decodeModels(entity, _decode(response));
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    final HttpResourceMapping resource = _resource(entity.schema);
    final http.Response response = await _request(resource.keys, entity.schema);
    final Object? body = mapping.jsonCodec.keys(_decode(response));
    if (body is! List) throw const FormatException('Expected a JSON list.');
    return body.map((value) {
      if (value is Map) {
        return _decodeIdentity(entity, _map(value));
      }
      return value as I;
    }).toList(growable: false);
  }

  @override
  Future<void> pop<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async {
    final HttpResourceMapping resource = _resource(entity.schema);
    try {
      await _request(resource.delete, entity.schema, id: id);
    } on HttpDatabaseException catch (error) {
      if (error.statusCode != 404) rethrow;
    }
  }

  @override
  Future<void> popKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Iterable<I> ids,
  ) async {
    final List<I> keys = ids.toList();
    if (keys.isEmpty) return;
    final HttpResourceMapping resource = _resource(entity.schema);
    final HttpEndpoint? endpoint = resource.deleteKeys;
    if (endpoint == null) {
      throw UnsupportedError('This HTTP resource has no delete-keys endpoint.');
    }
    final List<Object?> encoded = [
      for (final I id in keys) _encodedIdentity(entity, id),
    ];
    await _request(endpoint, entity.schema, body: encoded);
  }

  Object? _encodedIdentity<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) {
    final List<Object?> values = entity.primaryKeyCodec.encode(id);
    return values.length == 1 ? values.single : values;
  }

  @override
  Future<void> push<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
  ) async {
    final HttpResourceMapping resource = _resource(entity.schema);
    await _request(
      resource.update,
      entity.schema,
      id: entity.identify(model),
      body: _bodyForModel(entity, model, resource),
    );
  }

  @override
  Future<void> pushAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    List<Model> models,
  ) async {
    if (models.isEmpty) return;
    final HttpResourceMapping resource = _resource(entity.schema);
    final HttpEndpoint? endpoint = resource.updateAll;
    if (endpoint == null) {
      throw UnsupportedError('This HTTP resource has no update-all endpoint.');
    }
    await _request(
      endpoint,
      entity.schema,
      body: models
          .map((model) => _bodyForModel(entity, model, resource))
          .toList(),
    );
  }

  @override
  Future<void> popAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) async {
    final HttpResourceMapping resource = _resource(entity.schema);
    await _request(
      resource.deleteAll,
      entity.schema,
      query: _queryParameters(entity, filter),
    );
  }

  @override
  Future<void> patch<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
    Model? Function(Model?) update,
  ) async {
    final Model? existing = await peek(entity, id);
    final Model? updated = update(existing);
    if (updated == null) {
      await pop(entity, id);
    } else {
      await push(entity, updated);
    }
  }

  @override
  Future<Model> put<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) async {
    final ResolvedCreation<Data, I> resolved = _resolveCreation(
      entity,
      creation,
    );
    final Model model = entity.fromData(resolved);
    final HttpResourceMapping resource = _resource(entity.schema);
    final http.Response response = await _request(
      resource.create,
      entity.schema,
      id: entity.identify(model),
      body: _bodyForModel(entity, model, resource),
    );
    final Object? body = _decode(response);
    return body == null
        ? model
        : _decodeModel<Data, Model, I>(
            entity,
            mapping.jsonCodec.single(body),
            id: entity.identify(model),
          );
  }

  @override
  Future<List<Model>> putAll<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, List<C> creations) async {
    if (creations.isEmpty) return [];
    final HttpResourceMapping resource = _resource(entity.schema);
    final HttpEndpoint? endpoint = resource.createAll;
    if (endpoint == null) {
      throw UnsupportedError('This HTTP resource has no create-all endpoint.');
    }
    final List<Model> models = [
      for (final C creation in creations)
        entity.fromData(_resolveCreation(entity, creation)),
    ];
    final http.Response response = await _request(
      endpoint,
      entity.schema,
      body: models.map((model) => _bodyForModel(entity, model, resource)).toList(),
    );
    final Object? body = _decode(response);
    if (body == null) return models;
    return _decodeModels(entity, body);
  }

  @override
  Future<void> purge<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    await _request(_resource(entity.schema).purge, entity.schema);
  }

  @override
  Stream<Model?> pull<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    I id,
  ) async* {
    yield await peek(entity, id);
  }

  @override
  Stream<List<Model>> pullAll<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
  ) async* {
    yield await peekAll(entity, filter);
  }
}
