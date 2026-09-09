// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'error.dart';
import 'mapping.dart';
import 'query.dart';

class Reference implements BaseReference<Query, OffsetPageRequest> {
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

  HttpResourceMapping _resource(EntitySchema schema) =>
      mapping.resource(schema);

  Uri _uri(String path, {Map<String, String> query = const {}}) {
    final String relative = path.startsWith('/') ? path.substring(1) : path;
    return baseUri
        .resolve(relative)
        .replace(queryParameters: query.isEmpty ? null : query);
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

  I _decodeCreatedIdentity<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Object value,
  ) {
    if (entity.schema.isCompositePrimaryKey) {
      throw const FormatException(
        'A generated HTTP identity must belong to a single-key entity.',
      );
    }
    try {
      final I id = entity.primaryKeyCodec.decode([value]);
      _validateIdentity(entity, id);
      return id;
    } catch (error) {
      if (error is FormatException) rethrow;
      throw FormatException('The HTTP response contained an invalid identity.');
    }
  }

  Model _resolveCreatedItem<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation, HttpCreatedItem item) {
    return switch (item) {
      HttpCreatedIdentity(:final value) => entity.fromData(
        ResolvedCreation(
          dependency: creation.dependency,
          data: creation.data,
          id: _decodeCreatedIdentity(entity, value),
          identitySource: CreationIdentitySource.database,
        ),
      ),
      HttpCreatedData(:final data) => () {
        try {
          final I id = _decodeIdentity(entity, data);
          _validateIdentity(entity, id);
          return entity.fromJson(id, data);
        } catch (error) {
          if (error is FormatException) rethrow;
          throw const FormatException(
            'The HTTP response did not contain a valid identity.',
          );
        }
      }(),
    };
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

  Map<String, Object?>
  _bodyForModel<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Model model,
    HttpResourceMapping resource,
  ) {
    final Map<String, Object?> data = {...entity.toJson(model)};
    if (resource.identityLocation == HttpIdentityLocation.path ||
        resource.identityLocation == HttpIdentityLocation.none) {
      return data;
    }
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

  Map<String, Object?> _bodyForData<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    Data data,
  ) {
    final Map<String, Object?> result = {...entity.toJson(data)};
    for (final FieldSchema field in entity.schema.primaryKeys) {
      result.remove(field.columnName);
    }
    return result;
  }

  ResolvedCreation<Data, I> _resolveCreation<
    Data,
    Model extends Data,
    I extends Object,
    C extends Creation<Data, I>
  >(Entity<Data, Model, I, C> entity, C creation) {
    return switch (creation) {
      AutoCreation<Data, I>() => _resolveAuto(entity, creation),
      ExplicitCreation<Data, I>(:final identity) => () {
        _validateIdentity(entity, identity);
        return ResolvedCreation(
          dependency: creation.dependency,
          data: creation.data,
          id: identity,
          identitySource: CreationIdentitySource.explicit,
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
        entity.identityGeneration != IdentityGenerationStrategy.engine) {
      throw UnsupportedError(
        'HTTP creation requires an explicit identity for this entity.',
      );
    }
    return ResolvedCreation(
      dependency: creation.dependency,
      data: creation.data,
      id: const Uuid().v4() as I,
      identitySource: CreationIdentitySource.generated,
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

  Map<String, String>
  _queryParameters<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter, {
    QueryOptions options = const QueryOptions(),
  }) {
    final Query query = options.apply(
      filter.accept(Query(schema: entity.schema)),
    );
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
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) async {
    final HttpResourceMapping resource = _resource(entity.schema);
    final http.Response response = await _request(
      resource.collection,
      entity.schema,
      query: _queryParameters(entity, filter, options: options),
    );
    return _decodeModels(entity, _decode(response));
  }

  @override
  Future<Page<Model>> peekPage<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
    BaseFilter<Query> filter,
    OffsetPageRequest request,
  ) async {
    final List<Model> models = await peekAll(
      entity,
      filter,
      QueryOptions(
        orderBy: request.orderBy,
        limit: request.size + 1,
        offset: request.offset,
      ),
    );
    return Page(
      items: models.take(request.size).toList(),
      hasNext: models.length > request.size,
    );
  }

  @override
  Future<List<I>> peekAllKeys<Data, Model extends Data, I extends Object>(
    Entity<Data, Model, I, Creation<Data, I>> entity,
  ) async {
    final HttpResourceMapping resource = _resource(entity.schema);
    final http.Response response = await _request(resource.keys, entity.schema);
    final Object? body = mapping.jsonCodec.keys(_decode(response));
    if (body is! List) throw const FormatException('Expected a JSON list.');
    return body
        .map((value) {
          if (value is Map) {
            return _decodeIdentity(entity, _map(value));
          }
          return value as I;
        })
        .toList(growable: false);
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
    if (creation is AutoCreation<Data, I> &&
        entity.identityGeneration == IdentityGenerationStrategy.database) {
      final HttpResourceMapping resource = _resource(entity.schema);
      if (resource.identityLocation != HttpIdentityLocation.none) {
        throw UnsupportedError(
          'Database-generated HTTP creation requires identityLocation.none.',
        );
      }
      final http.Response response = await _request(
        resource.create,
        entity.schema,
        body: _bodyForData(entity, creation.data),
      );
      final Object? body = _decode(response);
      if (body == null) {
        throw const FormatException(
          'The HTTP creation response did not contain an identity.',
        );
      }
      final HttpCreatedItem item = mapping.creationCodec.decode(
        mapping.jsonCodec.single(body),
        entity.schema,
      );
      return _resolveCreatedItem<Data, Model, I, C>(entity, creation, item);
    }
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
    final bool hasAutomaticCreation = creations.any(
      (creation) => creation is AutoCreation<Data, I>,
    );
    if (hasAutomaticCreation &&
        entity.identityGeneration == IdentityGenerationStrategy.database) {
      if (creations.any((creation) => creation is! AutoCreation<Data, I>)) {
        throw UnsupportedError(
          'Database-generated HTTP putAll requires automatic creations only.',
        );
      }
      if (resource.identityLocation != HttpIdentityLocation.none) {
        throw UnsupportedError(
          'Database-generated HTTP creation requires identityLocation.none.',
        );
      }
      final http.Response response = await _request(
        endpoint,
        entity.schema,
        body: creations
            .cast<AutoCreation<Data, I>>()
            .map((creation) => _bodyForData(entity, creation.data))
            .toList(),
      );
      final Object? body = _decode(response);
      final List<Object?> items = mapping.jsonCodec.list(body);
      if (items.length != creations.length) {
        throw StateError(
          'The HTTP creation response contained ${items.length} items, '
          'but ${creations.length} were requested.',
        );
      }
      return List<Model>.generate(
        creations.length,
        (index) => _resolveCreatedItem(
          entity,
          creations[index],
          mapping.creationCodec.decode(items[index], entity.schema),
        ),
        growable: false,
      );
    }
    final List<Model> models = [
      for (final C creation in creations)
        entity.fromData(_resolveCreation(entity, creation)),
    ];
    final http.Response response = await _request(
      endpoint,
      entity.schema,
      body: models
          .map((model) => _bodyForModel(entity, model, resource))
          .toList(),
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
    BaseFilter<Query> filter, [
    QueryOptions options = const QueryOptions(),
  ]) async* {
    yield await peekAll(entity, filter, options);
  }
}
