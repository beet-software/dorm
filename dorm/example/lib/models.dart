import 'package:decimal/decimal.dart';
import 'package:dorm/dorm.dart';
import 'package:dorm_annotations/dorm_annotations.dart';

part 'models.dorm.dart';

part 'models.g.dart';

@Data()
abstract class _Profile {
  @Field(name: 'name')
  String get name;

  @Field(name: 'birth-date')
  DateTime get birthDate;

  @Field(name: 'bio')
  String? get bio;
}

@Model(name: 'Users', as: #users)
abstract class _User {
  @Field(name: 'username')
  String get username;

  @Field(name: 'email')
  String get email;

  @ModelField(name: 'profile', referTo: _Profile)
  get profile;

  @QueryField(
    name: '_q-username',
    referTo: [QueryToken(#username, QueryType.text)],
  )
  // ignore: unused_element
  String get _qUsername;
}

@Model(name: 'Products', as: #products)
abstract class _Product {
  @Field(name: 'name')
  String get name;

  @Field(name: 'description')
  String get description;

  @Field(name: 'price')
  Decimal get price;

  @QueryField(
    name: '_q-name',
    referTo: [QueryToken(#name, QueryType.text)],
  )
  // ignore: unused_element
  String get _qName;
}

@Model(name: 'Carts', as: #carts, uidType: UidType.sameAs(_User))
abstract class _Cart {
  @Field(name: 'timestamp')
  DateTime get timestamp;

  @ForeignField(name: 'user-id', referTo: _User)
  String get userId;
}

@Model(name: 'CartItems', as: #cartItems)
abstract class _CartItem {
  @Field(name: 'amount')
  int get amount;

  @ForeignField(name: 'product-id', referTo: _Product)
  String get productId;

  @ForeignField(name: 'cart-id', referTo: _Cart)
  String get cartId;
}

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
  // Use `Field` instead of `ForeignField`
  @Field(name: 'user-id')
  String get userId;
}

@Model(name: 'Reviews', as: #reviews)
abstract class _Review {
  @Field(name: 'text')
  String get text;

  @Field(name: 'timestamp')
  DateTime get timestamp;

  @PolymorphicField(name: 'content', pivotName: 'type')
  _ReviewContent get content;

  @ForeignField(name: 'user-id', referTo: _User)
  String get userId;

  @QueryField(
    name: '_q-type',
    referTo: [QueryToken(#userId), QueryToken(#type, QueryType.enumeration)],
    joinBy: '_',
  )
  // ignore: unused_element
  String get _qUserIdType;
}
