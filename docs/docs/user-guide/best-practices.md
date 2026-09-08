# Best practices

These conventions are optional. They keep application code consistent as the
number of models and data sources grows.

## Keep `Dorm` in your dependency container

When the application already uses [`get_it`](https://pub.dev/packages/get_it), register the configured `Dorm`
facade once and retrieve that same instance where repositories are needed:

```dart title="lib/main.dart"
import 'package:dorm_framework/dorm_framework.dart';
import 'package:dorm_bloc_database/dorm_bloc_database.dart' as dorm_bloc;
import 'package:get_it/get_it.dart';

final GetIt services = GetIt.instance;

void configureServices(Dorm<dorm_bloc.Query, OffsetPageRequest> dorm) {
  services.registerSingleton<Dorm<dorm_bloc.Query, OffsetPageRequest>>(dorm);
}

final Dorm<dorm_bloc.Query, OffsetPageRequest> dorm =
    GetIt.instance.get<Dorm<dorm_bloc.Query, OffsetPageRequest>>();
```

This keeps connection ownership and engine configuration in one place. The
pattern is optional; a constructor parameter, another dependency container, or
a local variable can provide the same `Dorm` instance.

`get_it` is not required by dORM. Add it only when it is already part of the
application's dependency-management approach.

## Keep model declarations in a dedicated library

For a new application, use `lib/models.dart` as the default location for
annotated models. Keep the generated parts beside that source file:

```text
lib/
  models.dart
  models.dorm.dart
  models.g.dart
```

This location and filename are conventions, not generator requirements. An
annotated Dart library can live anywhere in the application and can use any
filename. The generated files follow the source library's path and basename;
for example, `lib/catalog/product.dart` uses `product.dorm.dart` and
`product.g.dart` in the same directory. Update the `part` directives to match
the names you choose:

```dart
part 'product.dorm.dart';
part 'product.g.dart';
```

Use `lib/models.dart` when one central model library keeps the project easier
to navigate. Choose a different path when the application groups models by
feature or bounded context.

## Give persisted fields explicit names

Declare `name` on every `@Field`, `@ForeignField`, and `@ModelField`, even when
it matches the Dart getter name:

```dart title="lib/models.dart"
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'profiles', as: #profiles)
abstract class _Profile {}

@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'email')
  String get email;

  @ForeignField(name: 'profile-id', referTo: _Profile)
  String get profileId;
}
```

The Dart getter is the name used by application code. The annotation `name`
is the name used by the selected engine when it stores or queries the value.
Keeping both names visible makes that boundary clear when a field is renamed
in Dart or when the storage schema already uses a different spelling.

## Use a `Props` extension for application-only getters

Keep computed or presentation-oriented getters outside the annotated model
class. A `UserProps` extension is a convenient convention for properties that
do not belong in the persisted schema:

```dart title="lib/user_props.dart"
extension UserProps on User {
  String get displayName => username.trim();

  bool get hasProfile => profile != null;
}
```

Because these getters are not annotated fields, they are not added to the
generated schema or serialized automatically. Use `@Field` on the source
model when a value must be persisted or queried.
