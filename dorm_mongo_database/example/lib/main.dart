import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_mongo_database/dorm_mongo_database.dart' as dorm;
import 'package:mongo_dart/mongo_dart.dart';

import 'models.dart';

Future<void> main() async {
  final String uri =
      Platform.environment['MONGO_URI'] ??
      'mongodb://127.0.0.1:27017/dorm_example';
  final Db database = Db(uri);
  await database.open();

  try {
    await database.collection('users').deleteMany({});
    await database.collection('posts').deleteMany({});

    final Dorm context = Dorm(dorm.Engine(database));
    final User user = await context.users.repository.put(
      const Creation.auto(
        dependency: UserDependency(),
        data: UserData(name: 'Ada'),
      ),
    );
    await context.posts.repository.push(
      Post(id: 'post-1', title: 'First post', userId: user.id),
    );

    final List<User> users = await context.users.repository.peekAll(
      dorm.Filter.text('Ad', key: UserEntity.fields.name.fieldName),
    );
    final List<Join<User, Post>> posts = await context.relations.users.posts
        .peekAll();
    final List<User?> initialRead = await context.users.repository
        .pull(user.id)
        .toList();

    print('Users: ${users.map((item) => item.name).toList()}');
    print('Posts: ${posts.map((item) => item.right.title).toList()}');
    print('Initial stream read: ${initialRead.single?.name}');
  } finally {
    await database.collection('posts').deleteMany({});
    await database.collection('users').deleteMany({});
    await database.close();
  }
}
