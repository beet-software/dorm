import 'package:device_preview/device_preview.dart';
import 'package:dorm_bloc_database/dorm_bloc_database.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Engine engine = Engine();

  // It's recommended to have a way to access a global instance of the generated
  // `Dorm` class. Here, we are using dependency injection with a great solution
  // called `get_it`, but you are free to use `provider` or any other method.
  GetIt.instance.registerSingleton<Dorm>(Dorm(engine));

  runApp(DevicePreview(
    defaultDevice: DeviceInfo.genericPhone(
      platform: TargetPlatform.android,
      id: '',
      name: '',
      screenSize: const Size(360, 800),
    ),
    isToolbarVisible: false,
    builder: (_) => const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    title: Text(user.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            final String? updatedName = await showDialog(
                              context: context,
                              builder: (_) => const TextInputDialog(
                                title: 'Update user',
                              ),
                            );
                            if (updatedName == null) return;
                            await GetIt.instance
                                .get<Dorm>()
                                .users
                                .repository
                                .push(User(id: user.id, name: updatedName));
                          },
                          child: const Text('edit'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () async {
                            await GetIt.instance
                                .get<Dorm>()
                                .users
                                .repository
                                .pop(user.id);
                          },
                          child: const Text(
                            'delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final String? name = await showDialog(
                context: context,
                builder: (_) => const TextInputDialog(
                  title: 'Create user',
                ),
              );
              if (name == null) return;
              await GetIt.instance
                  .get<Dorm>()
                  .users
                  .repository
                  .put(const UserDependency(), UserData(name: name));
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class TextInputDialog extends StatelessWidget {
  final String title;

  const TextInputDialog({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TextEditingController>(
          create: (_) => TextEditingController(),
        ),
      ],
      child: AlertDialog(
        title: Text(title),
        icon: const Icon(Icons.supervisor_account),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Consumer<TextEditingController>(
            builder: (context, controller, _) {
              return TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Name',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('cancel', style: TextStyle(color: Colors.red)),
          ),
          Consumer<TextEditingController>(
            builder: (context, controller, _) {
              return TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('submit'),
              );
            },
          ),
        ],
      ),
    );
  }
}
