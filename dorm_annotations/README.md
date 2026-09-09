# dorm_annotations

<p>
  <a href="https://pub.dev/packages/dorm_annotations"><img src="https://img.shields.io/pub/v/dorm_annotations.svg?label=dorm_annotations" alt="dorm_annotations on pub.dev"></a>
  <a href="https://pub.dev/packages/dorm_annotations"><img src="https://img.shields.io/pub/points/dorm_annotations?logo=dart" alt="dorm_annotations pub points"></a>
  <a href="https://pub.dev/packages/dorm_annotations"><img src="https://img.shields.io/pub/popularity/dorm_annotations?logo=dart" alt="dorm_annotations popularity"></a>
  <a href="https://pub.dev/packages/dorm_annotations"><img src="https://img.shields.io/pub/likes/dorm_annotations?logo=dart" alt="dorm_annotations likes"></a>
  <a href="https://ezgrs.github.io/dorm/annotations/"><img src="https://img.shields.io/badge/documentation-dORM-4c8bf5?style=flat" alt="dorm_annotations documentation"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/badge/repository-GitHub-181717?logo=github&style=flat" alt="dORM repository"></a>
  <a href="https://github.com/beet-software/dorm"><img src="https://img.shields.io/github/license/beet-software/dorm?style=flat" alt="License"></a>
  <a href="https://github.com/beet-software/dorm/actions/workflows/dart.yml"><img src="https://github.com/beet-software/dorm/actions/workflows/dart.yml/badge.svg" alt="Dart CI"></a>
</p>

dorm_annotations contains the annotations that describe dORM models, fields,
identities, and relationships. It is the declarative layer used by
dorm_generator.

## Install

Add the annotations to the application that owns the model declarations:

~~~shell
dart pub add dorm_annotations
~~~

Add dorm_generator and build_runner as development dependencies when the
application is ready to generate its model API:

~~~shell
dart pub add --dev dorm_generator
dart pub add --dev build_runner
~~~

## Declare a model

A model declaration gives dORM the storage name and the repository accessor
name. The annotated class is the source declaration; generated model types are
created later.

~~~dart
import 'package:dorm_annotations/dorm_annotations.dart';

@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;

  @Field(name: 'email')
  String get email;
}
~~~

Always declare the persisted name when the field is part of a storage contract.
The generated schema then remains explicit even when a Dart getter is renamed.

## Fields and defaults

Field annotations map getters to persisted values:

~~~dart
@Field(name: 'display_name', defaultValue: 'Anonymous')
String get displayName;

@Field(name: 'birth_date')
DateTime? get birthDate;
~~~

The generated API keeps the Dart property name and the persisted column or
document name as separate values. A nullable field without an explicit default
uses null as its default.

## Identities

The Model annotation declares the primary-key specification. A generated
identity is created by the selected engine:

~~~dart
@Model(
  name: 'products',
  as: #products,
  primaryKey: [
    GeneratedIdSpec(as: #id, name: 'id', type: String),
  ],
)
abstract class _Product {
  @Field(name: 'name')
  String get name;
}
~~~

A database or remote backend can provide a simple identity after creation:

~~~dart
@Model(
  name: 'products',
  as: #products,
  primaryKey: [
    DatabaseGeneratedIdSpec(as: #id, name: 'id', type: int),
  ],
)
abstract class _Product {
  @Field(name: 'name')
  String get name;
}
~~~

An existing getter can be the identity:

~~~dart
@Model(
  name: 'users',
  as: #users,
  primaryKey: [
    ExistingIdSpec(referTo: #username),
  ],
)
abstract class _User {
  @Field(name: 'username')
  String get username;
}
~~~

A composite identity lists its existing key fields in their declared order:

~~~dart
@Model(
  name: 'cart_items',
  as: #cartItems,
  primaryKey: [
    ExistingIdSpec(referTo: #cartId),
    ExistingIdSpec(referTo: #productId),
  ],
)
abstract class _CartItem {
  @Field(name: 'cart_id')
  String get cartId;

  @Field(name: 'product_id')
  String get productId;
}
~~~

The engine must support the identity strategy used by the model. Composite
identities are supplied explicitly when creating records.

## Foreign fields and relationships

ForeignField keeps a related identity in the model and generates relationship
accessors:

~~~dart
@Model(name: 'carts', as: #carts)
abstract class _Cart {
  @ForeignField(
    name: 'user_id',
    referTo: _User,
    as: #user,
    inverseAs: #cart,
  )
  String get userId;
}
~~~

The referTo type identifies the target model. as names the forward relationship
accessor. inverseAs names the accessor generated on the target model. Use
unique: true when the foreign key is unique in the source model.

## Embedded model values

ModelField represents a nested model or data value. Its template describes the
Dart shape generated for the getter:

~~~dart
@Model(name: 'users', as: #users)
abstract class _User {
  @ModelField(
    name: 'profile',
    referTo: _Profile,
    template: ModelFieldTemplate<_Profile?>(),
  )
  _Profile? get profile;
}
~~~

Use ModelFieldTemplate<List<_Profile>>() for a list of nested values. This
feature is most useful when the backend stores JSON-like or document-shaped
values.

## Derived values

DerivedField declares a synchronous static callback. The callback result is
materialized with the model and can then be queried through its persisted name:

~~~dart
@Model(name: 'users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;

  @DerivedField(name: 'q-username')
  static String $dorm$derived$qUsername(
    _User model,
    DerivedTransformations transformations,
  ) {
    return transformations.text(model.username) ?? '';
  }
}
~~~

The callback runs in Dart before persistence. DerivedTransformations provides
text, enumeration, date, and datetime normalization. The callback may also
compose values manually. The result must be serializable by the selected
backend.

## Polymorphic values

PolymorphicData describes the possible data variants stored in a polymorphic
field:

~~~dart
abstract class _ReviewContent {}

@PolymorphicData(name: 'text', as: #text)
abstract class _TextReviewContent implements _ReviewContent {
  @Field(name: 'text')
  String get text;
}

@PolymorphicData(name: 'rating', as: #rating)
abstract class _RatingReviewContent implements _ReviewContent {
  @Field(name: 'rating')
  int get rating;
}

@Model(name: 'reviews', as: #reviews)
abstract class _Review {
  @PolymorphicField(
    name: 'content',
    pivotName: 'content_type',
  )
  _ReviewContent get content;
}
~~~

Use this feature when a single persisted value can have different model
shapes. The generated serializer stores the discriminator and the selected
variant according to the generated schema.

## Source and generated code

Keep the annotations in a normal Dart source file, commonly lib/models.dart:

~~~dart
part 'models.dorm.dart';
part 'models.g.dart';
~~~

The annotations package describes the source. dorm_generator creates the
entities, repositories, schema metadata, and serialization parts. Edit the
annotated source and regenerate; do not edit generated files manually.

## Next steps

- [dorm_generator](https://pub.dev/packages/dorm_generator)
- [dorm_framework](https://pub.dev/packages/dorm_framework)
- [Annotation reference](https://ezgrs.github.io/dorm/annotations/)
- [Model annotation](https://ezgrs.github.io/dorm/annotations/model/)
- [DerivedField](https://ezgrs.github.io/dorm/annotations/derived-field/)
- [GitHub repository](https://github.com/beet-software/dorm)
