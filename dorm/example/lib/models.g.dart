// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

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
  return CartData(
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
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
  return CartItemData(
    amount: json['amount'] as int,
  );
}

Map<String, dynamic> _$CartItemDataToJson(CartItemData instance) =>
    <String, dynamic>{
      'amount': instance.amount,
    };

CartItem _$CartItemFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['amount', '_id', 'product-id', 'cart-id'],
    disallowNullValues: const ['amount', '_id', 'product-id', 'cart-id'],
  );
  return CartItem(
    id: json['_id'] as String,
    amount: json['amount'] as int,
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
    requiredKeys: const ['text', 'timestamp', 'type', 'content', '_id'],
    disallowNullValues: const ['text', 'timestamp', 'type', 'content', '_id'],
  );
  return Review._(
    id: json['_id'] as String,
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: $enumDecode(_$ReviewContentTypeEnumMap, json['type']),
    content: json['content'] as Map,
  );
}

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
      'text': instance.text,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': _$ReviewContentTypeEnumMap[instance.type]!,
      'content': instance.content.toJson(),
      '_id': instance.id,
    };

ProductReviewContent _$ProductReviewContentFromJson(Map json) {
  $checkKeys(
    json,
    requiredKeys: const ['rating'],
    disallowNullValues: const ['rating'],
  );
  return ProductReviewContent(
    rating: json['rating'] as int,
  );
}

Map<String, dynamic> _$ProductReviewContentToJson(
        ProductReviewContent instance) =>
    <String, dynamic>{
      'rating': instance.rating,
    };

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
        ServiceReviewContent instance) =>
    <String, dynamic>{
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
    requiredKeys: const ['tags'],
    disallowNullValues: const ['tags'],
  );
  return UserReviewContent(
    tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  );
}

Map<String, dynamic> _$UserReviewContentToJson(UserReviewContent instance) =>
    <String, dynamic>{
      'tags': instance.tags,
    };
