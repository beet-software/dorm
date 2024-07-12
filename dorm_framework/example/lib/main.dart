import 'package:device_preview/device_preview.dart';
import 'package:dorm_bloc_database/dorm_bloc_database.dart' as dorm_bloc;
import 'package:dorm_framework/dorm_framework.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'models.dart' show Dorm;
import 'screens/users.dart';

const bool useFirebase = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final BaseEngine<dorm_bloc.Query> engine = dorm_bloc.Engine();
  GetIt.instance.registerSingleton<Dorm>(Dorm(engine));
  runApp(DevicePreview(
    defaultDevice: DeviceInfo.genericPhone(
      platform: TargetPlatform.android,
      id: 'dorm_example',
      name: 'dorm_example',
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
      title: 'dORM Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UsersScreen(),
    );
  }
}
