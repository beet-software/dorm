import 'package:dorm_framework/dorm_framework.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:test/test.dart';

import 'repository_test.mocks.dart';

class ModelData {
  final int value;

  const ModelData(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelData &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ModelData($value)';
}

class Model extends ModelData {
  final String id;

  const Model(super.value, {required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is Model &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => super.hashCode ^ id.hashCode;

  @override
  String toString() => 'Model($value, id: \'$id\')';
}

class ModelDependency extends Dependency<ModelData> {
  const ModelDependency() : super.strong();
}

class Query extends MockBaseQuery<Query> {}

@GenerateNiceMocks([
  MockSpec<BaseReference>(),
  MockSpec<BaseRelationship>(),
  MockSpec<BaseQuery>(),
  MockSpec<Dependency>(),
  MockSpec<Entity>(),
])
void main() {
  const Dependency<ModelData> dependency = ModelDependency();

  late MockBaseReference<Query> referenceMock;
  late MockBaseRelationship<Query> relationshipMock;
  late MockEntity<ModelData, Model, String, SimpleCreation<ModelData, String>>
  entityMock;
  late Repository<
    ModelData,
    Model,
    String,
    Query,
    SimpleCreation<ModelData, String>
  >
  repository;

  setUp(() {
    referenceMock = MockBaseReference();
    relationshipMock = MockBaseRelationship();
    entityMock = MockEntity();
    repository = Repository(
      reference: referenceMock,
      relationship: relationshipMock,
      entity: entityMock,
    );
  });
  tearDown(() {
    mockito.resetMockitoState();
  });

  group('create', () {
    test('put', () async {
      final SimpleCreation<ModelData, String> creation = Creation.auto(
        dependency: dependency,
        data: ModelData(1),
      );
      mockito
          .when(referenceMock.put(entityMock, creation))
          .thenAnswer((_) async => const Model(1, id: '1'));

      final Model model = await repository.put(creation);
      expect(model.id, '1');
      expect(model.value, 1);

      mockito.verify(referenceMock.put(entityMock, creation)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('putAll', () async {
      final List<SimpleCreation<ModelData, String>> creations = [
        Creation.auto(dependency: dependency, data: ModelData(1)),
        Creation.auto(dependency: dependency, data: ModelData(2)),
      ];
      mockito
          .when(referenceMock.putAll(entityMock, creations))
          .thenAnswer(
            (_) async => [const Model(1, id: '1'), const Model(2, id: '2')],
          );

      final List<Model> models = await repository.putAll(creations);
      expect(models.length, 2);
      expect(models[0].id, '1');
      expect(models[0].value, 1);
      expect(models[1].id, '2');
      expect(models[1].value, 2);

      mockito.verify(referenceMock.putAll(entityMock, creations)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
  });
  group('read', () {
    test('peek', () async {
      mockito
          .when(referenceMock.peek(entityMock, '1'))
          .thenAnswer((_) async => const Model(1, id: '1'));

      final Model? model = await repository.peek('1');
      expect(model, isNotNull);
      expect(model?.id, '1');
      expect(model?.value, 1);

      mockito.verify(referenceMock.peek(entityMock, '1')).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('pull', () async {
      mockito
          .when(referenceMock.pull(entityMock, '1'))
          .thenAnswer((_) => Stream.value(const Model(1, id: '1')));

      expect(await repository.pull('1').single, const Model(1, id: '1'));

      mockito.verify(referenceMock.pull(entityMock, '1')).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('peekAll', () async {
      const BaseFilter<Query> filter = BaseFilter.value(1, key: 'value');
      mockito
          .when(referenceMock.peekAll(entityMock, filter))
          .thenAnswer((_) async => [const Model(1, id: '1')]);

      expect(await repository.peekAll(filter), [const Model(1, id: '1')]);

      mockito.verify(referenceMock.peekAll(entityMock, filter)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('pullAll', () async {
      const BaseFilter<Query> filter = BaseFilter.value(1, key: 'value');
      mockito
          .when(referenceMock.pullAll(entityMock, filter))
          .thenAnswer((_) => Stream.value([const Model(1, id: '1')]));

      expect(await repository.pullAll(filter).single, [
        const Model(1, id: '1'),
      ]);

      mockito.verify(referenceMock.pullAll(entityMock, filter)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('peekAllKeys', () async {
      mockito
          .when(referenceMock.peekAllKeys(entityMock))
          .thenAnswer((_) async => ['1', '2']);

      expect(await repository.peekAllKeys(), ['1', '2']);

      mockito.verify(referenceMock.peekAllKeys(entityMock)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
  });

  group('write', () {
    test('pop', () async {
      await repository.pop('1');

      mockito.verify(referenceMock.pop(entityMock, '1')).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('popKeys', () async {
      final List<String> ids = ['1', '2'];

      await repository.popKeys(ids);

      mockito.verify(referenceMock.popKeys(entityMock, ids)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('popAll', () async {
      const BaseFilter<Query> filter = BaseFilter.value(1, key: 'value');

      await repository.popAll(filter);

      mockito.verify(referenceMock.popAll(entityMock, filter)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('push', () async {
      const Model model = Model(1, id: '1');

      await repository.push(model);

      mockito.verify(referenceMock.push(entityMock, model)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('pushAll', () async {
      final List<Model> models = [
        const Model(1, id: '1'),
        const Model(2, id: '2'),
      ];

      await repository.pushAll(models);

      mockito.verify(referenceMock.pushAll(entityMock, models)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('patch', () async {
      Model? update(Model? model) => model;

      await repository.patch('1', update);

      mockito.verify(referenceMock.patch(entityMock, '1', update)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
    test('purge', () async {
      await repository.purge();

      mockito.verify(referenceMock.purge(entityMock)).called(1);
      mockito.verifyNoMoreInteractions(referenceMock);
      mockito.verifyZeroInteractions(entityMock);
      mockito.verifyZeroInteractions(relationshipMock);
    });
  });
}
