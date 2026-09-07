import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:dorm_firestore_database/dorm_firestore_database.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models.dart';

Future<void> main() async {
  await Firebase.initializeApp();

  final fs.FirebaseFirestore firestore = fs.FirebaseFirestore.instance;
  final String? emulator = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  if (emulator != null) {
    final List<String> parts = emulator.split(':');
    firestore.useFirestoreEmulator(
      parts.first,
      int.parse(parts.length == 1 ? '8080' : parts.last),
    );
  }

  final Engine engine = Engine(firestore);
  final Dorm<Query, OffsetPageRequest> dorm = Dorm(engine);

  final User user = await dorm.users.repository.put(
    Creation.auto<UserData, String>(
      dependency: const UserDependency(),
      data: const UserData(name: 'Ada'),
    ),
  );
  await dorm.posts.repository.put(
    Creation.explicit<PostData, String>(
      dependency: PostDependency(userId: user.id),
      data: const PostData(title: 'First post'),
      identity: 'post-1',
    ),
  );

  final List<User> users = await dorm.users.repository.peekAll(
    const Filter.text('Ad', key: 'name'),
  );
  final List<Join<User, Post>> posts = await dorm.relations.users.posts
      .peekAll();

  print('Users: ${users.map((item) => item.name).toList()}');
  print('Posts: ${posts.map((item) => item.right.title).toList()}');
}
