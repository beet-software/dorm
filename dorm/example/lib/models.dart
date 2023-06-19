import 'package:decimal/decimal.dart';
import 'package:dorm/dorm.dart';
import 'package:dorm_annotations/dorm_annotations.dart';

part 'models.g.dart';
part 'models.dorm.dart';

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
    referTo: [QueryToken(#username, QueryType.text)],
  )
  String get _qName;
}

@Model(name: 'Orders', as: #orders, uidType: UidType.sameAs(_User))
abstract class _Order {
  @Field(name: 'total-amount')
  int get amount;

  @Field(name: 'timestamp')
  DateTime get timestamp;

  @ForeignField(name: 'user-id', referTo: _User)
  String get userId;
}

@Model(name: 'OrderItems', as: #orderItems)
abstract class _OrderItem {
  @Field(name: 'quantity')
  int get quantity;

  @ForeignField(name: 'product-id', referTo: _Product)
  String get productId;

  @ForeignField(name: 'order-id', referTo: _Order)
  String get orderId;
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
  @Field(name: 'tags', defaultValue: [])
  List<String> get tags;
}

@Model(name: 'Reviews', as: #reviews)
abstract class _Review {
  @Field(name: 'text')
  String get text;

  @Field(name: 'timestamp')
  DateTime get timestamp;

  @PolymorphicField(name: 'content', pivotName: 'type')
  _ReviewContent get content;

  @QueryField(
    name: '_q-type',
    referTo: [QueryToken(#type, QueryType.enumeration)],
  )
  String get _qType;
}
