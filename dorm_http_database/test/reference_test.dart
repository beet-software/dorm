import 'dart:convert';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_http_database/dorm_http_database.dart';
import 'package:dorm_http_database/src/reference.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _Data {
  final String name;

  const _Data(this.name);
}

class _Model extends _Data {
  final String id;

  const _Model({required this.id, required String name}) : super(name);
}

class _Entity
    implements Entity<_Data, _Model, String, Creation<_Data, String>> {
  const _Entity();

  @override
  final EntitySchema schema = const EntitySchema(
    tableName: 'users',
    primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
    fields: [FieldSchema(fieldName: 'name', columnName: 'name')],
  );

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  bool get supportsAutomaticIdentity => true;

  @override
  _Model fromData(ResolvedCreation<_Data, String> creation) =>
      _Model(id: creation.id, name: creation.data.name);

  @override
  _Model fromJson(String id, Map data) =>
      _Model(id: id, name: data['name'] as String);

  @override
  String identify(_Model model) => model.id;

  @override
  Map<String, Object?> toJson(_Data data) => {'name': data.name};

  @override
  _Model convert(_Model model, _Data data) =>
      _Model(id: model.id, name: data.name);
}

void main() {
  const _Entity entity = _Entity();

  HttpMapping mapping() {
    return HttpMapping.byTableName({
      'users': HttpResourceMapping(
        path: 'users',
        createAll: HttpEndpoint('POST', 'users/batch'),
        updateAll: HttpEndpoint('PUT', 'users/batch'),
        deleteKeys: HttpEndpoint('POST', 'users/delete'),
      ),
    });
  }

  test('reads a model and sends configured headers and URI', () async {
    final MockClient client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.toString(), 'https://example.test/api/users/u-1');
      expect(request.headers['x-token'], 'secret');
      return http.Response(jsonEncode({'id': 'u-1', 'name': 'Ada'}), 200);
    });
    final Reference reference = Reference(
      client: client,
      baseUri: Uri.parse('https://example.test/api/'),
      mapping: mapping(),
      headers: const {'x-token': 'secret'},
    );

    final _Model? model = await reference.peek(entity, 'u-1');

    expect(model?.id, 'u-1');
    expect(model?.name, 'Ada');
  });

  test('returns null for a missing item', () async {
    final Reference reference = Reference(
      client: MockClient((_) async => http.Response('', 404)),
      baseUri: Uri.parse('https://example.test/api/'),
      mapping: mapping(),
      headers: const {},
    );

    expect(await reference.peek(entity, 'missing'), isNull);
  });

  test('writes JSON with the identity in the body', () async {
    final MockClient client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(jsonDecode(request.body), {'id': 'u-1', 'name': 'Ada'});
      return http.Response('', 204);
    });
    final Reference reference = Reference(
      client: client,
      baseUri: Uri.parse('https://example.test/api/'),
      mapping: mapping(),
      headers: const {},
    );

    await reference.push(entity, const _Model(id: 'u-1', name: 'Ada'));
  });

  test('uses an envelope codec for collection reads', () async {
    final MockClient client = MockClient((request) async {
      expect(request.url.queryParameters['name__startsWith'], 'A');
      return http.Response(
        jsonEncode({
          'data': [
            {'id': 'u-1', 'name': 'Ada'},
          ],
        }),
        200,
      );
    });
    final Reference reference = Reference(
      client: client,
      baseUri: Uri.parse('https://example.test/api/'),
      mapping: HttpMapping.byTableName({
        'users': HttpResourceMapping(path: 'users'),
      }, jsonCodec: HttpJsonCodec.envelope()),
      headers: const {},
    );

    final List<_Model> models = await reference.peekAll(
      entity,
      const Filter.text('A', key: 'name'),
    );

    expect(models.single.name, 'Ada');
  });

  test('fails clearly when a batch endpoint is absent', () async {
    final Reference reference = Reference(
      client: MockClient((_) async => http.Response('', 200)),
      baseUri: Uri.parse('https://example.test/api/'),
      mapping: HttpMapping.byTableName({
        'users': HttpResourceMapping(path: 'users'),
      }),
      headers: const {},
    );

    expect(
      () => reference.pushAll(entity, const [_Model(id: '1', name: 'A')]),
      throwsUnsupportedError,
    );
  });
}
