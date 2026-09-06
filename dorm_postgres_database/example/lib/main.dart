import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_postgres_database/dorm_postgres_database.dart';
import 'package:postgres/postgres.dart';

import 'models.dart';

String _requiredEnvironment(String name) {
  final String? value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError('Set $name before running this example.');
  }
  return value;
}

Future<void> main() async {
  final Connection connection = await Connection.open(
    Endpoint(
      host: _requiredEnvironment('POSTGRES_HOST'),
      port: int.parse(_requiredEnvironment('POSTGRES_PORT')),
      database: _requiredEnvironment('POSTGRES_DATABASE'),
      username: _requiredEnvironment('POSTGRES_USERNAME'),
      password: _requiredEnvironment('POSTGRES_PASSWORD'),
    ),
  );

  try {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS posts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        user_id TEXT NOT NULL REFERENCES users(id)
      )
    ''');

    final Dorm dorm = Dorm(Engine(connection));
    final User user = await dorm.users.repository.put(
      const UserDependency(),
      const UserData(name: 'Ada'),
    );
    await dorm.posts.repository.push(
      Post(id: 'post-1', title: 'First post', userId: user.id),
    );

    final List<User> users = await dorm.users.repository.peekAll(
      Filter.text('Ad', key: UserEntity.fields.name.fieldName),
    );
    final List<Join<User, Post>> posts = await dorm.relations.users.posts
        .peekAll();

    print('Users: ${users.map((item) => item.name).toList()}');
    print('Posts: ${posts.map((item) => item.right.title).toList()}');
  } finally {
    await connection.close();
  }
}
