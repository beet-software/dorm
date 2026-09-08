import 'package:decimal/decimal.dart';
import 'package:dorm_framework/dorm_framework.dart';
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

  @DerivedField(
    name: '_q-username',
    referTo: [DerivedToken(#username, DerivedTransform.text)],
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

  @DerivedField(
    name: '_q-name',
    referTo: [DerivedToken(#name, DerivedTransform.text)],
  )
  // ignore: unused_element
  String get _qName;
}

@Model(name: 'Carts', as: #carts)
abstract class _Cart {
  static String $dorm$generateId(_Cart cart, String id) => cart.userId;
  @Field(name: 'timestamp')
  DateTime get timestamp;

  @ForeignField(name: 'user-id', referTo: _User, inverseAs: #carts)
  String get userId;
}

@Model(name: 'CartItems', as: #cartItems)
abstract class _CartItem {
  @Field(name: 'amount')
  int get amount;

  @ForeignField(name: 'product-id', referTo: _Product, inverseAs: #cartItems)
  String get productId;

  @ForeignField(name: 'cart-id', referTo: _Cart, inverseAs: #items)
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

  @ForeignField(name: 'user-id', referTo: _User, inverseAs: #reviews)
  String get userId;

  @DerivedField(
    name: '_q-type',
    referTo: [
      DerivedToken(#userId),
      DerivedToken(#type, DerivedTransform.enumeration),
    ],
    joinBy: '_',
  )
  // ignore: unused_element
  String get _qUserIdType;
}
