# Build the first store model

Start with the single-field `User` model. Expand it into a small e-commerce application with users, embedded profile data, and products.

## The store domain

The first entities in the store application are:

| Entity | Stored information | Role in the application |
| --- | --- | --- |
| `User` | `username`, `email`, and `profile` | User records |
| `Profile` | `name`, `birthDate`, and optional `bio` | Embedded data inside a user |
| `Product` | `name`, `description`, and `price` | Catalog records |

The store domain also includes `Cart`, `CartItem`, and `Review`. They use the same annotated source file and are introduced after the first user and product records.

## Keep the generated parts with the source file

The annotated source declares both generated parts:

```dart
part 'models.dorm.dart';
part 'models.g.dart';
```

The source file contains the model declarations. The generated parts contain the concrete data classes, model classes, dependencies, schema metadata, repositories, and JSON helpers created from those declarations.

## Add embedded profile data

`Profile` is a plain data type annotated with `Data`. It is used as a field of `User` rather than as a separate `Model` table:

```dart
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

The generated `Profile` value contains the three fields. The nullable Dart type on `bio` is reflected in the generated JSON metadata.

## Define the user model

Add the user fields and connect the embedded profile with `ModelField`:

```dart
@Model(name: 'Users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;

  @Field(name: 'email')
  String get email;

  @ModelField(name: 'profile', referTo: _Profile)
  get profile;

  @DerivedField(
    name: '_q-username',
    referTo: [DerivedToken(#username, DerivedTransform.text)],
  )
  // ignore: unused_element
  String get _qUsername;
}
```

The `name` value is the stored table name. The `as` value supplies the generated accessor name, so the generated database object exposes `dorm.users`.

The `DerivedField` declaration creates a stored value from `username`. Its `DerivedToken` marks the value as text for username search.

## Define the product model

Add the catalog entity with a text-derived field for product-name searches:

```dart
import 'package:decimal/decimal.dart';

@Model(name: 'Products', as: #products)
abstract class _Product {
  @Field(name: 'name')
  String get name;

  @Field(name: 'description')
  String get description;

  @Field(name: 'price')
  Decimal get price;

  @DerivedField(
    name: '_q-name',
    referTo: [DerivedToken(#name, DerivedTransform.text)],
  )
  // ignore: unused_element
  String get _qName;
}
```

Add the `decimal` package when the model uses `Decimal`:

```shell
dart pub add decimal
```

The `name` and `description` getters become stored fields. `price` is a serializable custom value in the product model.

Combine the declarations above in `lib/models.dart` with the imports and `part` directives from the quickstart.

## Create the generated data values

The generator produces `UserData` and `ProductData` from the `Field` and `ModelField` declarations in these models:

```dart
final UserData userData = UserData(
  username: 'ada',
  email: 'ada@example.com',
  profile: Profile(
    name: 'Ada Lovelace',
    birthDate: DateTime(1815, 12, 10),
    bio: null,
  ),
);

final ProductData productData = ProductData(
  name: 'Notebook',
  description: 'A lined notebook',
  price: Decimal.fromInt(12),
);
```

`Data` values contain the information supplied when a record is created or updated. The generated model adds its identity and relationship fields.

## Generate after changing the declarations

From the application directory, regenerate both generated parts:

```shell
dart run build_runner build
```

Keep generated `.dorm.dart` and `.g.dart` files beside the source model file. Edit the source declarations and regenerate these output files after changes.

[Generate the model](03-generate-the-model.md) shows the generated types and repository accessors produced from these declarations.
