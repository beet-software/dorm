import 'dart:io';

import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_http_database/dorm_http_database.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

Future<void> main() async {
  final String rawBaseUri =
      Platform.environment['HTTP_BASE_URI'] ??
      (throw StateError('Set HTTP_BASE_URI before running this example.'));
  final http.Client client = http.Client();

  final Engine engine = Engine(
    client: client,
    baseUri: Uri.parse(rawBaseUri),
    mapping: HttpMapping.byTableName({
      'users': HttpResourceMapping(
        path: 'users',
        createAll: const HttpEndpoint('POST', 'users/batch'),
        updateAll: const HttpEndpoint('PUT', 'users/batch'),
        deleteKeys: const HttpEndpoint('POST', 'users/delete'),
      ),
      'posts': HttpResourceMapping(
        path: 'posts',
        createAll: const HttpEndpoint('POST', 'posts/batch'),
        updateAll: const HttpEndpoint('PUT', 'posts/batch'),
        deleteKeys: const HttpEndpoint('POST', 'posts/delete'),
      ),
    }),
  );

  try {
    final Dorm dorm = Dorm(engine);
    final User user = await dorm.users.repository.put(
      Creation.auto<UserData, String>(
        dependency: const UserDependency(),
        data: const UserData(name: 'Ada'),
      ),
    );
    await dorm.posts.repository.push(
      Post(id: 'post-1', title: 'First post', userId: user.id),
    );

    final List<User> users = await dorm.users.repository.peekAll(
      const Filter.text('Ad', key: 'name'),
    );
    final List<Join<User, Post>> posts = await dorm.relations.users.posts
        .peekAll();

    print('Users: ${users.map((item) => item.name).toList()}');
    print('Posts: ${posts.map((item) => item.right.title).toList()}');
  } finally {
    client.close();
  }
}
