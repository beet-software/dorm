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
    test('pull', () {});
    test('peekAll', () {});
    test('pullAll', () {});
    test('peekAllKeys', () {});
  });
}
