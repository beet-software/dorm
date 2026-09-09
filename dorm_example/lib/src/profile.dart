enum ExamplePlatform { flutter, dart }

class ExampleProfile {
  final String name;
  final String packageName;
  final ExamplePlatform platform;
  final bool jsonFeatures;
  final bool docker;
  final bool transactions;
  final bool reactiveStreams;
  final bool requiresEnvironment;
  final bool firebaseEmulator;
  final bool httpServer;
  final String minimumDart;

  const ExampleProfile({
    required this.name,
    required this.packageName,
    required this.platform,
    required this.jsonFeatures,
    this.docker = false,
    required this.transactions,
    required this.reactiveStreams,
    required this.requiresEnvironment,
    this.firebaseEmulator = false,
    this.httpServer = false,
    this.minimumDart = '3.11.5',
  });

  bool get isFlutter => platform == ExamplePlatform.flutter;

  Map<String, Object> toTemplateContext(String projectName) => {
    'engine': name,
    'enginePackage': packageName,
    'projectName': projectName,
    'isFlutter': isFlutter,
    'isDart': !isFlutter,
    'jsonFeatures': jsonFeatures,
    'docker': docker,
    'transactions': transactions,
    'reactiveStreams': reactiveStreams,
    'requiresEnvironment': requiresEnvironment,
    'firebaseEmulator': firebaseEmulator,
    'httpServer': httpServer,
    'minimumDart': minimumDart,
    'sql': name == 'postgres' || name == 'mysql' || name == 'sqlite',
    'hasVolumes': name == 'postgres' || name == 'mysql' || name == 'mongo',
    'postgres': name == 'postgres',
    'mysql': name == 'mysql',
    'mongo': name == 'mongo',
    'isFirebase': name == 'firebase',
    'isFirestore': name == 'firestore',
    'isHttp': name == 'http',
  };
}

class ExampleProfiles {
  static const List<ExampleProfile> all = [
    ExampleProfile(
      name: 'memory',
      packageName: 'dorm_memory_database',
      platform: ExamplePlatform.flutter,
      jsonFeatures: true,
      transactions: true,
      reactiveStreams: true,
      requiresEnvironment: false,
    ),
    ExampleProfile(
      name: 'bloc',
      packageName: 'dorm_bloc_database',
      platform: ExamplePlatform.flutter,
      jsonFeatures: true,
      transactions: true,
      reactiveStreams: true,
      requiresEnvironment: false,
    ),
    ExampleProfile(
      name: 'firebase',
      packageName: 'dorm_firebase_database',
      platform: ExamplePlatform.flutter,
      jsonFeatures: true,
      transactions: false,
      reactiveStreams: true,
      requiresEnvironment: false,
      docker: true,
      firebaseEmulator: true,
    ),
    ExampleProfile(
      name: 'firestore',
      packageName: 'dorm_firestore_database',
      platform: ExamplePlatform.flutter,
      jsonFeatures: true,
      transactions: false,
      reactiveStreams: true,
      requiresEnvironment: false,
      docker: true,
      firebaseEmulator: true,
    ),
    ExampleProfile(
      name: 'http',
      packageName: 'dorm_http_database',
      platform: ExamplePlatform.flutter,
      jsonFeatures: true,
      transactions: false,
      reactiveStreams: false,
      requiresEnvironment: false,
      docker: true,
      httpServer: true,
    ),
    ExampleProfile(
      name: 'postgres',
      packageName: 'dorm_postgres_database',
      platform: ExamplePlatform.dart,
      jsonFeatures: false,
      docker: true,
      transactions: true,
      reactiveStreams: false,
      requiresEnvironment: true,
    ),
    ExampleProfile(
      name: 'mysql',
      packageName: 'dorm_mysql_database',
      platform: ExamplePlatform.dart,
      jsonFeatures: false,
      docker: true,
      transactions: true,
      reactiveStreams: false,
      requiresEnvironment: true,
    ),
    ExampleProfile(
      name: 'mongo',
      packageName: 'dorm_mongo_database',
      platform: ExamplePlatform.dart,
      jsonFeatures: true,
      docker: true,
      transactions: false,
      reactiveStreams: false,
      requiresEnvironment: true,
    ),
    ExampleProfile(
      name: 'sqlite',
      packageName: 'dorm_sqlite_database',
      platform: ExamplePlatform.dart,
      jsonFeatures: false,
      transactions: true,
      reactiveStreams: true,
      requiresEnvironment: false,
    ),
  ];

  static ExampleProfile byName(String value) {
    for (final ExampleProfile profile in all) {
      if (profile.name == value) return profile;
    }
    throw ArgumentError.value(value, 'engine', 'Unknown dORM engine.');
  }
}
