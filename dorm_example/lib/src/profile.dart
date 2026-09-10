// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'release.dart';

/// Identifies whether a generated showcase runs with Dart or Flutter.
enum ExamplePlatform {
  /// A Flutter Web showcase.
  flutter,

  /// A pure Dart showcase.
  dart,
}

/// Describes the templates, dependencies, and capabilities of one engine profile.
class ExampleProfile {
  /// The command-line name of the engine profile.
  final String name;

  /// The dORM database package used by the generated project.
  final String packageName;

  /// The runtime platform of the generated project.
  final ExamplePlatform platform;

  /// Whether the generated models use document-oriented features.
  final bool jsonFeatures;

  /// Whether the generated project starts local infrastructure with Docker Compose.
  final bool docker;

  /// Whether the profile advertises transaction support in its showcase.
  final bool transactions;

  /// Whether the profile advertises reactive streams in its showcase.
  final bool reactiveStreams;

  /// Whether the generated application reads required environment variables.
  final bool requiresEnvironment;

  /// Whether the profile includes Firebase Emulator configuration.
  final bool firebaseEmulator;

  /// Whether the profile includes a local HTTP server.
  final bool httpServer;

  /// The minimum Dart SDK version rendered into the generated project.
  final String minimumDart;

  /// Creates an engine profile description.
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

  /// Whether the generated project uses the Flutter toolchain.
  bool get isFlutter => platform == ExamplePlatform.flutter;

  /// Builds the values consumed by the profile templates.
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
    'dormVersion': dormReleaseVersion,
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

/// Provides the engine profiles supported by the generator.
class ExampleProfiles {
  /// All engine profiles supported by this release.
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

  /// Finds a profile by its command-line name.
  static ExampleProfile byName(String value) {
    for (final ExampleProfile profile in all) {
      if (profile.name == value) return profile;
    }
    throw ArgumentError.value(value, 'engine', 'Unknown dORM engine.');
  }
}
