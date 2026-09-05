// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// User(...).copyWith(id: 12, name: "My name")
  /// ```
  User call({String id, String username, String email, Profile profile});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUser.copyWith(...)`.
class _$UserCWProxyImpl implements _$UserCWProxy {
  const _$UserCWProxyImpl(this._value);

  final User _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// User(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  User call({
    Object? id = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? profile = const $CopyWithPlaceholder(),
  }) {
    return User(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      username: username == const $CopyWithPlaceholder() || username == null
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      email: email == const $CopyWithPlaceholder() || email == null
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
      profile: profile == const $CopyWithPlaceholder() || profile == null
          ? _value.profile
          // ignore: cast_nullable_to_non_nullable
          : profile as Profile,
    );
  }
}

extension $UserCopyWith on User {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUser.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$UserCWProxy get copyWith => _$UserCWProxyImpl(this);
}

abstract class _$ProductCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Product(...).copyWith(id: 12, name: "My name")
  /// ```
  Product call({String id, String name, String description, Decimal price});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProduct.copyWith(...)`.
class _$ProductCWProxyImpl implements _$ProductCWProxy {
  const _$ProductCWProxyImpl(this._value);

  final Product _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Product(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Product call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? price = const $CopyWithPlaceholder(),
  }) {
    return Product(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      price: price == const $CopyWithPlaceholder() || price == null
          ? _value.price
          // ignore: cast_nullable_to_non_nullable
          : price as Decimal,
    );
  }
}

extension $ProductCopyWith on Product {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProduct.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$ProductCWProxy get copyWith => _$ProductCWProxyImpl(this);
}

abstract class _$CartCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Cart(...).copyWith(id: 12, name: "My name")
  /// ```
  Cart call({String id, DateTime timestamp, String userId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCart.copyWith(...)`.
class _$CartCWProxyImpl implements _$CartCWProxy {
  const _$CartCWProxyImpl(this._value);

  final Cart _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Cart(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Cart call({
    Object? id = const $CopyWithPlaceholder(),
    Object? timestamp = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
  }) {
    return Cart(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      timestamp: timestamp == const $CopyWithPlaceholder() || timestamp == null
          ? _value.timestamp
          // ignore: cast_nullable_to_non_nullable
          : timestamp as DateTime,
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
    );
  }
}

extension $CartCopyWith on Cart {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCart.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$CartCWProxy get copyWith => _$CartCWProxyImpl(this);
}

abstract class _$CartItemCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// CartItem(...).copyWith(id: 12, name: "My name")
  /// ```
  CartItem call({String id, int amount, String productId, String cartId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCartItem.copyWith(...)`.
class _$CartItemCWProxyImpl implements _$CartItemCWProxy {
  const _$CartItemCWProxyImpl(this._value);

  final CartItem _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// CartItem(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CartItem call({
    Object? id = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? productId = const $CopyWithPlaceholder(),
    Object? cartId = const $CopyWithPlaceholder(),
  }) {
    return CartItem(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      amount: amount == const $CopyWithPlaceholder() || amount == null
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      productId: productId == const $CopyWithPlaceholder() || productId == null
          ? _value.productId
          // ignore: cast_nullable_to_non_nullable
          : productId as String,
      cartId: cartId == const $CopyWithPlaceholder() || cartId == null
          ? _value.cartId
          // ignore: cast_nullable_to_non_nullable
          : cartId as String,
    );
  }
}

extension $CartItemCopyWith on CartItem {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCartItem.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$CartItemCWProxy get copyWith => _$CartItemCWProxyImpl(this);
}

abstract class _$ReviewCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Review(...).copyWith(id: 12, name: "My name")
  /// ```
  Review call({
    String id,
    String text,
    DateTime timestamp,
    ReviewContentType type,
    ReviewContent content,
    String userId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReview.copyWith(...)`.
class _$ReviewCWProxyImpl implements _$ReviewCWProxy {
  const _$ReviewCWProxyImpl(this._value);

  final Review _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// Review(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Review call({
    Object? id = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? timestamp = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
  }) {
    return Review(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      timestamp: timestamp == const $CopyWithPlaceholder() || timestamp == null
          ? _value.timestamp
          // ignore: cast_nullable_to_non_nullable
          : timestamp as DateTime,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as ReviewContentType,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as ReviewContent,
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
    );
  }
}

extension $ReviewCopyWith on Review {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReview.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$ReviewCWProxy get copyWith => _$ReviewCWProxyImpl(this);
}

abstract class _$ProductReviewContentCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// ProductReviewContent(...).copyWith(id: 12, name: "My name")
  /// ```
  ProductReviewContent call({int rating});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProductReviewContent.copyWith(...)`.
class _$ProductReviewContentCWProxyImpl
    implements _$ProductReviewContentCWProxy {
  const _$ProductReviewContentCWProxyImpl(this._value);

  final ProductReviewContent _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// ProductReviewContent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProductReviewContent call({Object? rating = const $CopyWithPlaceholder()}) {
    return ProductReviewContent(
      rating: rating == const $CopyWithPlaceholder() || rating == null
          ? _value.rating
          // ignore: cast_nullable_to_non_nullable
          : rating as int,
    );
  }
}

extension $ProductReviewContentCopyWith on ProductReviewContent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProductReviewContent.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$ProductReviewContentCWProxy get copyWith =>
      _$ProductReviewContentCWProxyImpl(this);
}

abstract class _$ServiceReviewContentCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// ServiceReviewContent(...).copyWith(id: 12, name: "My name")
  /// ```
  ServiceReviewContent call({ReviewSatisfaction rating});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServiceReviewContent.copyWith(...)`.
class _$ServiceReviewContentCWProxyImpl
    implements _$ServiceReviewContentCWProxy {
  const _$ServiceReviewContentCWProxyImpl(this._value);

  final ServiceReviewContent _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// ServiceReviewContent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServiceReviewContent call({Object? rating = const $CopyWithPlaceholder()}) {
    return ServiceReviewContent(
      rating: rating == const $CopyWithPlaceholder() || rating == null
          ? _value.rating
          // ignore: cast_nullable_to_non_nullable
          : rating as ReviewSatisfaction,
    );
  }
}

extension $ServiceReviewContentCopyWith on ServiceReviewContent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServiceReviewContent.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$ServiceReviewContentCWProxy get copyWith =>
      _$ServiceReviewContentCWProxyImpl(this);
}

abstract class _$UserReviewContentCWProxy {
  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// UserReviewContent(...).copyWith(id: 12, name: "My name")
  /// ```
  UserReviewContent call({String userId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUserReviewContent.copyWith(...)`.
class _$UserReviewContentCWProxyImpl implements _$UserReviewContentCWProxy {
  const _$UserReviewContentCWProxyImpl(this._value);

  final UserReviewContent _value;

  /// Creates a new instance with the provided field values.
  /// Passing `null` to a nullable field nullifies it, while `null` for a non-nullable field is ignored.
  ///
  /// Example:
  /// ```dart
  /// UserReviewContent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UserReviewContent call({Object? userId = const $CopyWithPlaceholder()}) {
    return UserReviewContent(
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
    );
  }
}

extension $UserReviewContentCopyWith on UserReviewContent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUserReviewContent.copyWith(...)`.
  // ignore: library_private_types_in_public_api
  _$UserReviewContentCWProxy get copyWith =>
      _$UserReviewContentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'birth-date'],
    disallowNullValues: const ['name', 'birth-date'],
  );
  return Profile(
    name: json['name'] as String,
    birthDate: DateTime.parse(json['birth-date'] as String),
    bio: json['bio'] as String?,
  );
}

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'name': instance.name,
  'birth-date': instance.birthDate.toIso8601String(),
  'bio': instance.bio,
};

UserData _$UserDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['username', 'email', 'profile'],
    disallowNullValues: const ['username', 'email', 'profile'],
  );
  return UserData(
    username: json['username'] as String,
    email: json['email'] as String,
    profile: Profile.fromJson(json['profile'] as Map),
  );
}

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
  'username': instance.username,
  'email': instance.email,
  'profile': instance.profile.toJson(),
};

User _$UserFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['username', 'email', 'profile', '_id'],
    disallowNullValues: const ['username', 'email', 'profile', '_id'],
  );
  return User(
    id: json['_id'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    profile: Profile.fromJson(json['profile'] as Map),
  );
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'username': instance.username,
  'email': instance.email,
  'profile': instance.profile.toJson(),
  '_id': instance.id,
};

ProductData _$ProductDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'description', 'price'],
    disallowNullValues: const ['name', 'description', 'price'],
  );
  return ProductData(
    name: json['name'] as String,
    description: json['description'] as String,
    price: Decimal.fromJson(json['price'] as String),
  );
}

Map<String, dynamic> _$ProductDataToJson(ProductData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'price': instance.price.toJson(),
    };

Product _$ProductFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['name', 'description', 'price', '_id'],
    disallowNullValues: const ['name', 'description', 'price', '_id'],
  );
  return Product(
    id: json['_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    price: Decimal.fromJson(json['price'] as String),
  );
}

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'price': instance.price.toJson(),
  '_id': instance.id,
};

CartData _$CartDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['timestamp'],
    disallowNullValues: const ['timestamp'],
  );
  return CartData(timestamp: DateTime.parse(json['timestamp'] as String));
}

Map<String, dynamic> _$CartDataToJson(CartData instance) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
};

Cart _$CartFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['timestamp', '_id', 'user-id'],
    disallowNullValues: const ['timestamp', '_id', 'user-id'],
  );
  return Cart(
    id: json['_id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    userId: json['user-id'] as String,
  );
}

Map<String, dynamic> _$CartToJson(Cart instance) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
  '_id': instance.id,
  'user-id': instance.userId,
};

CartItemData _$CartItemDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['amount'],
    disallowNullValues: const ['amount'],
  );
  return CartItemData(amount: (json['amount'] as num).toInt());
}

Map<String, dynamic> _$CartItemDataToJson(CartItemData instance) =>
    <String, dynamic>{'amount': instance.amount};

CartItem _$CartItemFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['amount', '_id', 'product-id', 'cart-id'],
    disallowNullValues: const ['amount', '_id', 'product-id', 'cart-id'],
  );
  return CartItem(
    id: json['_id'] as String,
    amount: (json['amount'] as num).toInt(),
    productId: json['product-id'] as String,
    cartId: json['cart-id'] as String,
  );
}

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'amount': instance.amount,
  '_id': instance.id,
  'product-id': instance.productId,
  'cart-id': instance.cartId,
};

ReviewData _$ReviewDataFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['text', 'timestamp', 'type', 'content'],
    disallowNullValues: const ['text', 'timestamp', 'type', 'content'],
  );
  return ReviewData._(
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: $enumDecode(_$ReviewContentTypeEnumMap, json['type']),
    content: json['content'] as Map,
  );
}

Map<String, dynamic> _$ReviewDataToJson(ReviewData instance) =>
    <String, dynamic>{
      'text': instance.text,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$ReviewContentTypeEnumMap[instance.type]!,
      'content': instance.content.toJson(),
    };

const _$ReviewContentTypeEnumMap = {
  ReviewContentType.product: 'product',
  ReviewContentType.service: 'service',
  ReviewContentType.user: 'user',
};

Review _$ReviewFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'text',
      'timestamp',
      'type',
      'content',
      '_id',
      'user-id',
    ],
    disallowNullValues: const [
      'text',
      'timestamp',
      'type',
      'content',
      '_id',
      'user-id',
    ],
  );
  return Review._(
    id: json['_id'] as String,
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: $enumDecode(_$ReviewContentTypeEnumMap, json['type']),
    content: json['content'] as Map,
    userId: json['user-id'] as String,
  );
}

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'text': instance.text,
  'timestamp': instance.timestamp.toIso8601String(),
  'type': _$ReviewContentTypeEnumMap[instance.type]!,
  'content': instance.content.toJson(),
  '_id': instance.id,
  'user-id': instance.userId,
};

ProductReviewContent _$ProductReviewContentFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['rating'],
    disallowNullValues: const ['rating'],
  );
  return ProductReviewContent(rating: (json['rating'] as num).toInt());
}

Map<String, dynamic> _$ProductReviewContentToJson(
  ProductReviewContent instance,
) => <String, dynamic>{'rating': instance.rating};

ServiceReviewContent _$ServiceReviewContentFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['satisfaction'],
    disallowNullValues: const ['satisfaction'],
  );
  return ServiceReviewContent(
    rating: $enumDecode(_$ReviewSatisfactionEnumMap, json['satisfaction']),
  );
}

Map<String, dynamic> _$ServiceReviewContentToJson(
  ServiceReviewContent instance,
) => <String, dynamic>{
  'satisfaction': _$ReviewSatisfactionEnumMap[instance.rating]!,
};

const _$ReviewSatisfactionEnumMap = {
  ReviewSatisfaction.good: 'good',
  ReviewSatisfaction.ok: 'ok',
  ReviewSatisfaction.bad: 'bad',
};

UserReviewContent _$UserReviewContentFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['user-id'],
    disallowNullValues: const ['user-id'],
  );
  return UserReviewContent(userId: json['user-id'] as String);
}

Map<String, dynamic> _$UserReviewContentToJson(UserReviewContent instance) =>
    <String, dynamic>{'user-id': instance.userId};
