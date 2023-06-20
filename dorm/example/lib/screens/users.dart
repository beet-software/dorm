import 'dart:async';

import 'package:dorm/dorm.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:example/screens/user.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import 'user_form.dart';

class _Query extends ValueNotifier<AsyncSnapshot<List<User>>> {
  StreamSubscription<void>? _subscription;
  Timer? _timer;

  _Query() : super(const AsyncSnapshot.waiting()) {
    _subscription = GetIt.instance
        .get<Dorm>()
        .users
        .repository
        .pullAll()
        .map((users) => AsyncSnapshot.withData(ConnectionState.active, users))
        .listen((snapshot) => value = snapshot);
  }

  String _text = '';

  String get text => _text;

  void updateFilter(String text) {
    _text = text;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      // Waits one second without user input to evaluate the query
      final String query = $normalizeText(text) ?? text;
      _subscription = GetIt.instance
          .get<Dorm>()
          .users
          .repository
          .pullAll(Filter.text(query, key: '_q-username'))
          .map((users) => AsyncSnapshot.withData(ConnectionState.active, users))
          .listen((snapshot) => value = snapshot);

      _timer = null;
    });
  }

  @override
  void dispose() {
    _timer = null;
    _subscription?.cancel();
    super.dispose();
  }
}

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<_Query>(create: (_) => _Query()),
      ],
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Users')),
          body: Consumer<_Query>(
            child: const Center(child: CircularProgressIndicator()),
            builder: (context, query, child) {
              final AsyncSnapshot<List<User>> snapshot = query.value;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return child!;
              }
              final List<User> users = snapshot.data!;
              return Column(
                children: [
                  if (users.isNotEmpty || query.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextFormField(
                        initialValue: query.text,
                        onChanged: query.updateFilter,
                        decoration: const InputDecoration(
                          hintText: 'Search username',
                          border: OutlineInputBorder(),
                          prefixText: '@ ',
                        ),
                      ),
                    ),
                  Expanded(
                    child: users.isEmpty
                        ? const Center(child: Text('No users.'))
                        : ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, i) {
                              final User user = users[i];
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(user.profile.name),
                                onTap: () async {
                                  await Navigator.of(context)
                                      .push(MaterialPageRoute(
                                    builder: (_) => UserScreen(userId: user.id),
                                  ));
                                },
                                subtitle: Text('@${user.username}'),
                                trailing: const Icon(Icons.chevron_right),
                              );
                            },
                          ),
                  ),
                ],
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
