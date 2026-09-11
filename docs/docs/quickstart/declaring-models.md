# Define users, profiles, and products

The first version of the store has three model concepts:

- `User` is a stored entity with an identity;
- `Profile` is embedded data inside a user;
- `Product` is a stored catalog entity with a decimal price.

Keep all three declarations in <i>lib/models.dart</i>. The next page will generate
the concrete Dart types and repositories from this file.

## Add the decimal value type

The product model uses `Decimal` for its price. Add the package before writing
the import:

```shell
dart pub add decimal
```

## Create the annotated source file

Create <i>lib/models.dart</i> with the imports and generated parts:

```dart title="lib/models.dart"
import 'package:decimal/decimal.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:dorm_framework/dorm_framework.dart';

part 'models.dorm.dart';
part 'models.g.dart';
```

The `part` declarations attach the dORM and JSON output to this source
library. Keep them beside the declarations so the generated types can be used
from the rest of the application.

## Define the embedded profile

Use `@Data` for a value that belongs to another model instead of having its
own repository:

```dart title="lib/models.dart"
@Data()
abstract class _Profile {
  @Field(name: 'name')
  String get name;

  @Field(name: 'birth-date')
  DateTime get birthDate;

  @Field(name: 'bio')
  String? get bio;
}
```

`Profile` has a fixed shape and is stored as part of `User`. Its nullable
`bio` field remains nullable in the generated JSON mapping.

## Define the user model

Use `@Model` for an entity that has its own identity and repository. Use
`@ModelField` to embed the profile:

```dart title="lib/models.dart"
@Model(name: 'Users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;

  @Field(name: 'email')
  String get email;

  @ModelField(name: 'profile', referTo: _Profile)
  get profile;
}
```

The `name` value is the stored table, collection, or resource name when the
selected engine uses one. The `as: #users` value produces the generated
`dorm.users` accessor.

## Define the product model

Add the catalog entity to the same source file:

```dart title="lib/models.dart"
@Model(name: 'Products', as: #products)
abstract class _Product {
  @Field(name: 'name')
  String get name;

  @Field(name: 'description')
  String get description;

  @Field(name: 'price')
  Decimal get price;
}
```

`name` and `description` are ordinary stored fields. `price` uses the
`Decimal` value type and is handled by the JSON serialization integration.

## Keep this domain as the example grows

The rest of the quickstart extends these declarations instead of starting a
new example:

| Next model | Added later for |
| --- | --- |
| `Cart` | One cart owned by a user. |
| `CartItem` | The product and quantity in a cart. |
| `Review` | A user-authored review with multiple content types. |

Those models add relationships and polymorphic data after the first user and
product read work.

## Learn the annotation details when needed

This page uses the smallest set of annotations needed to build the store. See
the [Annotations reference](../annotations/index.md) for identity
specifications, relationship fields, derived fields, and polymorphic fields.

Continue with [Generate the store API](generating-models.md).
