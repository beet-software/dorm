# dorm_annotations

Provides annotations related with dORM code generation.

## Getting started

Add the following entries to your *pubspec.yaml* file:

```yaml
dependencies:
  dorm_annotations:
    git:
      url: git@github.com:enzo-santos/dorm.git
      ref: main
      path: dorm_annotations

  json_annotation: ^4.6.0

dev_dependencies:
  build_runner: ^2.2.0
  dorm_generator:
    git:
      url: git@github.com:enzo-santos/dorm.git
      ref: main
      path: dorm_generator
```

Get your package dependencies:

```shell
dart pub get
```

## Usage

The package `json_annotation` exports three annotations (`Model`, `Field`, `ForeignField`) for you
create an ORM for your system. As an example, let's create a social network system with the
following models:

- *user*, with a name, birth date, email and profile picture URL;
- *post*, with its contents, creation date and the user which posted it; and
- *message*, with its contents, creation date, the sender user and the receiver user.

On a file named *social_network.dart*, declare private abstract classes that describe the models
above:

```dart
abstract class _User {
  String? get name;

  DateTime get birthDate;

  String get email;

  Uri get pictureUrl;
}

abstract class _Post {
  String get contents;

  DateTime get creationDate;

  String get userId;
}

abstract class _Message {
  String get contents;

  DateTime get creationDate;

  String get senderId;

  String get receiverId;
}
```

Annotate all the classes with the `Model` annotation, giving it appropriate parameters:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'user', repositoryName: 'users')
abstract class _User {
  String? get name;

  DateTime get birthDate;

  String get email;

  Uri get pictureUrl;
}

@Model(name: 'post', repositoryName: 'posts')
abstract class _Post {
  String get contents;

  DateTime get creationDate;

  String get userId;
}

@Model(name: 'message', repositoryName: 'messages')
abstract class _Message {
  String get contents;

  DateTime get creationDate;

  String get senderId;

  String get receiverId;
}
```

Annotate all the fields with the `Field`/`ForeignField` annotation, giving it appropriate
parameters:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'user', repositoryName: 'users')
abstract class _User {
  @Field(name: 'name')
  String? get name;

  @Field(name: 'birth-date')
  DateTime get birthDate;

  @Field(name: 'email')
  String get email;

  @Field(name: 'picture-url')
  Uri get pictureUrl;
}

@Model(name: 'post', repositoryName: 'posts')
abstract class _Post {
  @Field(name: 'contents')
  String get contents;

  @Field(name: 'creation-date')
  DateTime get creationDate;

  @ForeignField(name: 'user-id', referTo: _User)
  String get userId;
}

@Model(name: 'message', repositoryName: 'messages')
abstract class _Message {
  @Field(name: 'contents')
  String get contents;

  @Field(name: 'creation-date')
  DateTime get creationDate;

  @ForeignField(name: 'sender-id', referTo: _User)
  String get senderId;

  @ForeignField(name: 'receiver-id', referTo: _User)
  String get receiverId;
}
```

On the top of the file, add the `json_annotation` import and the following part-declarations:

```dart
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:json_annotation/json_annotation.dart';

part 'social_network.dorm.dart';

part 'social_network.g.dart';

// ...
```

Run the code generation using any of the commands below:

```shell
dart run build_runner build
flutter pub run build_runner build
```

Two files will be generated on the same directory: *social_network.g.dart* and
*social_network.dorm.dart*. The most important component is `Dorm`, which you can use to operate 
your models in the database.

See the `example` directory to see an example of the generated code.
