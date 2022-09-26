import 'package:dorm/dorm.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'repository_test.mocks.dart';

class UserData {
  final String name;
  final DateTime birthDate;
  final int height;
  final double weight;
  final bool alive;

  const UserData({
    required this.name,
    required this.birthDate,
    required this.height,
    required this.weight,
    required this.alive,
  });
}

class User extends UserData {
  final String id;
  final String motherId;
  final String? fatherId;

  const User({
    required this.id,
    required this.motherId,
    required this.fatherId,
    required super.name,
    required super.birthDate,
    required super.height,
    required super.weight,
    required super.alive,
  });
}

class UserDependency extends Dependency<UserData> {
  final String motherId;
  final String? fatherId;

  UserDependency({
    required this.motherId,
    required this.fatherId,
  }) : super.weak([motherId, fatherId ?? '']);
}


@GenerateNiceMocks([
  MockSpec<Reference>(as: #MockReference),
  MockSpec<Entity<UserData, User>>(as: #MockEntity, fallbackGenerators: {
    #fromJson: entityFromJson,
    #fromData: entityFromData,
    #convert: entityConvert,
  }),
])
void main() {
  final MockReference reference = MockReference();
  final MockEntity entity = MockEntity();
  final Repository<UserData, User> repository =
      Repository(root: reference, entity: entity);

  tearDown(() {
    resetMockitoState();
  });

  test('te', () {
    when(reference.key).thenReturn('users');
    when(reference.child(any)).thenReturn(reference);
    when(reference.push()).thenReturn(reference);
    repository.put(
      UserDependency(
        motherId: 'e39e74fb4e80ba656f773669ed50315a',
        fatherId: 'd52e32f3a96a64786814ae9b5279fbe5',
      ),
      UserData(
        name: 'Paul McCartney',
        birthDate: DateTime(1932, 6, 13),
        height: 165,
        weight: 98,
        alive: true,
      ),
    );

    verify(reference.push()).called(1);
  });
}

User entityFromJson(String? id, Map? data) => throw 1;

User entityFromData(
  Dependency<UserData>? dependency,
  String? id,
  UserData? data,
) {
  dependency as UserDependency?;
  return User(
    id: id ?? '',
    motherId: dependency?.motherId ?? '',
    fatherId: dependency?.fatherId,
    name: data?.name ?? '',
    height: data?.height ?? 0,
    birthDate: data?.birthDate ?? DateTime.now(),
    alive: data?.alive ?? true,
    weight: data?.weight ?? 0,
  );
}

User entityConvert(User? model, UserData? data) {
  return User(
    id: model?.id ?? '',
    motherId: model?.motherId ?? '',
    fatherId: model?.fatherId,
    name: data?.name ?? '',
    height: data?.height ?? 0,
    birthDate: data?.birthDate ?? DateTime.now(),
    alive: data?.alive ?? true,
    weight: data?.weight ?? 0,
  );
}
