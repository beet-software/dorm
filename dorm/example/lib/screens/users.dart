import 'package:example/screens/user.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import 'user_form.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<AsyncSnapshot<List<User>>>(
          initialData: const AsyncSnapshot.waiting(),
          create: (_) => GetIt.instance
              .get<Dorm>()
              .users
              .repository
              .pullAll()
              .map((event) =>
                  AsyncSnapshot.withData(ConnectionState.active, event)),
        ),
      ],
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Users')),
          body: Consumer<AsyncSnapshot<List<User>>>(
            child: const Center(child: CircularProgressIndicator()),
            builder: (context, snapshot, child) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return child!;
              }
              final List<User> users = snapshot.data!;
              if (users.isEmpty) {
                return const Center(child: Text('No users.'));
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final User user = users[i];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.profile.name),
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => UserScreen(userId: user.id)));
                    },
                    subtitle: Text('@${user.username}'),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              final UserData? data =
                  await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UserFormScreen(form: UserForm()),
              ));
              if (data == null) return;
              await GetIt.instance
                  .get<Dorm>()
                  .users
                  .repository
                  .put(const UserDependency(), data);
            },
          ),
        ),
      ),
    );
  }
}
