# Add reviews with multiple content types

The store's `Review` model contains common fields and one of several content shapes. A review has text, a timestamp, an author, and a `content` value whose fields depend on its `type`.

The model declares three content variants. The parameters used by this example
are defined in the [`@PolymorphicData`](../annotations/polymorphic-data.md) and
[`@PolymorphicField`](../annotations/polymorphic-field.md) pages; this page
focuses on adding the review flow to the store.

- `product` stores an integer `rating`;
- `service` stores a `ReviewSatisfaction` value;
- `user` stores a `user-id`.

## Declare the content variants

Declare the shared content type and each variant in the annotated source:

```dart title="Declare review content variants in lib/models.dart"
abstract class _ReviewContent {}

@PolymorphicData(name: 'product', as: #product)
abstract class _ProductReviewContent implements _ReviewContent {
  @Field(name: 'rating')
  int get rating;
}

enum ReviewSatisfaction { good, ok, bad }

@PolymorphicData(name: 'service', as: #service)
abstract class _ServiceReviewContent implements _ReviewContent {
  @Field(name: 'satisfaction')
  ReviewSatisfaction get rating;
}

@PolymorphicData(name: 'user', as: #user)
abstract class _UserReviewContent implements _ReviewContent {
  @Field(name: 'user-id')
  String get userId;
}
```

Connect the variants to the review with a pivot field:

```dart title="Connect variants to the Review model"
@Model(name: 'Reviews', as: #reviews)
abstract class _Review {
  @Field(name: 'text')
  String get text;

  @Field(name: 'timestamp')
  DateTime get timestamp;

  @PolymorphicField(name: 'content', pivotName: 'type')
  _ReviewContent get content;

  @ForeignField(name: 'user-id', referTo: _User, inverseAs: #reviews)
  String get userId;
}
```

`@PolymorphicField` connects the selected variant to the review's
discriminator. The dedicated annotation pages describe the generated types and
the supported polymorphic declaration in detail.

Regenerate the generated parts after changing these declarations:

```shell title="Regenerate the review model API"
dart run build_runner build
```

## Create a product review

Construct the generated variant and place it in `ReviewData`:

```dart
final Review review = await dorm.reviews.repository.put(
  Creation.auto(
    dependency: ReviewDependency(userId: user.id),
    data: ReviewData(
      text: 'The product matched the description.',
      timestamp: DateTime.now(),
      type: ReviewContentType.product,
      content: const ProductReviewContent(rating: 5),
    ),
  ),
);
```

The `type` and `content` values describe the same variant. For service content, construct `ServiceReviewContent` and use `ReviewContentType.service`. For a user-targeted review, construct `UserReviewContent` and use `ReviewContentType.user`.

The review author is separate from the polymorphic target. `ReviewDependency(userId: user.id)` fills the `user-id` foreign field; the content variant describes what the review is about.

## Read and search reviews

Read reviews written by one user with a value filter:

```dart
final List<Review> reviews = await dorm.reviews.repository.peekAll(
  Filter.value(user.id, field: ReviewEntity.fields.userId),
);
```

The model also declares `_q-type`, a derived field composed from `userId` and the normalized `type`. Build the same derived value when filtering one user's reviews by variant:

```dart
final List<Review> productReviews = await dorm.reviews.repository.peekAll(
  Filter.text(
    '${user.id}_product',
    field: ReviewEntity.fields.qType,
  ),
);
```

The generated derived field uses the enum normalization used by dORM. Use the generated enum value's normalized representation when constructing a query value rather than relying on the enum's display text.

## Keep embedded data and polymorphic data distinct

`Profile` is embedded data: `User` always has one `profile` value with a fixed shape. Review content is polymorphic data: the `type` discriminator selects one of several generated shapes.

Both forms become generated Dart values and JSON-serializable fields. They differ in how the generated model determines the fields available for a record: `Profile` has one fixed schema, while `ReviewContent` dispatches through `ReviewContentType`.

Continue with [forms and live reads](forms-and-live-reads.md) to connect these
generated values to application input and stream consumers.
