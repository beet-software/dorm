import 'package:device_preview/device_preview.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_bloc_database/dorm_bloc_database.dart' as dorm_bloc;
import 'package:dorm_firebase_database/dorm_firebase_database.dart'
    as dorm_firebase;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'models.dart' show Dorm;
import 'screens/users.dart';

const bool useFirebase = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final BaseReference reference;
  if (useFirebase) {
    const String host = 'localhost';
    const int port = 9000;
    const String projectId = 'react-native-firebase-testing';
    await dorm_firebase.Firebase.initializeApp(
      options: const dorm_firebase.FirebaseOptions(
        apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
        authDomain: '$projectId.firebaseapp.com',
        databaseURL: 'https://$projectId.firebaseio.com',
        projectId: projectId,
        storageBucket: '$projectId.appspot.com',
        messagingSenderId: '448618578101',
        appId: '1:448618578101:web:772d484dc9eb15e9ac3efc',
        measurementId: 'G-0N1G9FLDZE',
      ),
    );
    dorm_firebase.FirebaseDatabase.instance.useDatabaseEmulator(host, port);
    reference = dorm_firebase.Reference(const dorm_firebase.FirebaseInstance());
  } else {
    reference = dorm_bloc.Reference();
  }

  GetIt.instance.registerSingleton<Dorm>(Dorm(reference));
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
