// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'models.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(anyMap: true, explicitToJson: true)
class Profile implements _Profile {
  factory Profile.fromJson(Map json) => _$ProfileFromJson(json);

  const Profile({
    required this.name,
    required this.birthDate,
    required this.bio,
  });

  @override
  @JsonKey(name: 'name', required: true, disallowNullValue: true)
  final String name;

  @override
  @JsonKey(name: 'birth-date', required: true, disallowNullValue: true)
  final DateTime birthDate;

  @override
  @JsonKey(name: 'bio')
  final String? bio;

  Map<String, Object?> toJson() => _$ProfileToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class UserData {
  factory UserData.fromJson(Map json) => _$UserDataFromJson(json);

  const UserData({
    required this.username,
    required this.email,
    required this.profile,
  });

  @JsonKey(name: 'username', required: true, disallowNullValue: true)
  final String username;

  @JsonKey(name: 'email', required: true, disallowNullValue: true)
  final String email;

  @JsonKey(name: 'profile', required: true, disallowNullValue: true)
  final Profile profile;

  Map<String, Object?> toJson() => _$UserDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class User extends UserData implements _User {
  factory User.fromJson(String id, Map json) =>
      _$UserFromJson({...json, '_id': id});

  const User({
    required this.id,
    required super.username,
    required super.email,
    required super.profile,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  String get _qUsername => [$normalizeText(username)].join('_');

  @override
  Map<String, Object?> toJson() {
    return {..._$UserToJson(this)..remove('_id'), '_q-username': _qUsername};
  }
}

class UserDependency extends Dependency<UserData> {
  const UserDependency() : super.strong();
}

class UserFields {
  const UserFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema username = const FieldSchema(
    fieldName: 'username',
    columnName: 'username',
  );

  final FieldSchema email = const FieldSchema(
    fieldName: 'email',
    columnName: 'email',
  );

  final FieldSchema profile = const FieldSchema(
    fieldName: 'profile',
    columnName: 'profile',
  );
}

class UserEntity implements Entity<UserData, User, String> {
  const UserEntity();

  static const UserFields fields = UserFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'Users',
    primaryKey: fields.id,
    fields: [fields.username, fields.email, fields.profile],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  User fromData(UserDependency dependency, String id, UserData data) {
    return User(
      id: id,
      username: data.username,
      email: data.email,
      profile: data.profile,
    );
  }

  @override
  User convert(User model, UserData data) => model.updateWith(data);

  @override
  User fromJson(String id, Map json) => User.fromJson(id, json);

  @override
  String identify(User model) => model.id;

  @override
  Map<String, Object?> toJson(UserData data) => data.toJson();
}

extension UserProperties on User {
  User updateWith(UserData data) {
    return User(
      id: id,
      username: data.username,
      email: data.email,
      profile: data.profile,
    );
  }
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class ProductData {
  factory ProductData.fromJson(Map json) => _$ProductDataFromJson(json);

  const ProductData({
    required this.name,
    required this.description,
    required this.price,
  });

  @JsonKey(name: 'name', required: true, disallowNullValue: true)
  final String name;

  @JsonKey(name: 'description', required: true, disallowNullValue: true)
  final String description;

  @JsonKey(name: 'price', required: true, disallowNullValue: true)
  final Decimal price;

  Map<String, Object?> toJson() => _$ProductDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class Product extends ProductData implements _Product {
  factory Product.fromJson(String id, Map json) =>
      _$ProductFromJson({...json, '_id': id});

  const Product({
    required this.id,
    required super.name,
    required super.description,
    required super.price,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  String get _qName => [$normalizeText(name)].join('_');

  @override
  Map<String, Object?> toJson() {
    return {..._$ProductToJson(this)..remove('_id'), '_q-name': _qName};
  }
}

class ProductDependency extends Dependency<ProductData> {
  const ProductDependency() : super.strong();
}

class ProductFields {
  const ProductFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema name = const FieldSchema(
    fieldName: 'name',
    columnName: 'name',
  );

  final FieldSchema description = const FieldSchema(
    fieldName: 'description',
    columnName: 'description',
  );

  final FieldSchema price = const FieldSchema(
    fieldName: 'price',
    columnName: 'price',
  );
}

class ProductEntity implements Entity<ProductData, Product, String> {
  const ProductEntity();

  static const ProductFields fields = ProductFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'Products',
    primaryKey: fields.id,
    fields: [fields.name, fields.description, fields.price],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  Product fromData(ProductDependency dependency, String id, ProductData data) {
    return Product(
      id: id,
      name: data.name,
      description: data.description,
      price: data.price,
    );
  }

  @override
  Product convert(Product model, ProductData data) => model.updateWith(data);

  @override
  Product fromJson(String id, Map json) => Product.fromJson(id, json);

  @override
  String identify(Product model) => model.id;

  @override
  Map<String, Object?> toJson(ProductData data) => data.toJson();
}

extension ProductProperties on Product {
  Product updateWith(ProductData data) {
    return Product(
      id: id,
      name: data.name,
      description: data.description,
      price: data.price,
    );
  }
}

class _$Cart implements _Cart {
  factory _$Cart.fromData(CartDependency dependency, CartData data) =>
      _$Cart(timestamp: data.timestamp, userId: dependency.userId);

  const _$Cart({required this.timestamp, required this.userId});

  @override
  final DateTime timestamp;

  @override
  final String userId;
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class CartData {
  factory CartData.fromJson(Map json) => _$CartDataFromJson(json);

  const CartData({required this.timestamp});

  @JsonKey(name: 'timestamp', required: true, disallowNullValue: true)
  final DateTime timestamp;

  Map<String, Object?> toJson() => _$CartDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class Cart extends CartData implements _Cart {
  factory Cart.fromJson(String id, Map json) =>
      _$CartFromJson({...json, '_id': id});

  const Cart({
    required this.id,
    required super.timestamp,
    required this.userId,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'user-id', required: true, disallowNullValue: true)
  final String userId;

  @override
  Map<String, Object?> toJson() {
    return {..._$CartToJson(this)..remove('_id')};
  }
}

class CartDependency extends Dependency<CartData> {
  CartDependency({required this.userId}) : super.weak([userId]);

  final String userId;
}

class CartFields {
  const CartFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema timestamp = const FieldSchema(
    fieldName: 'timestamp',
    columnName: 'timestamp',
  );

  final ForeignKeySchema userId = const ForeignKeySchema(
    fieldName: 'userId',
    columnName: 'user-id',
    targetTableName: 'Users',
    targetColumnName: 'id',
    unique: false,
  );
}

class CartEntity implements Entity<CartData, Cart, String> {
  const CartEntity();

  static const CartFields fields = CartFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'Carts',
    primaryKey: fields.id,
    fields: [fields.timestamp, fields.userId],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  Cart fromData(CartDependency dependency, String id, CartData data) {
    return Cart(
      id: _Cart._generate(_$Cart.fromData(dependency, data), id),
      timestamp: data.timestamp,
      userId: dependency.userId,
    );
  }

  @override
  Cart convert(Cart model, CartData data) => model.updateWith(data);

  @override
  Cart fromJson(String id, Map json) => Cart.fromJson(id, json);

  @override
  String identify(Cart model) => model.id;

  @override
  Map<String, Object?> toJson(CartData data) => data.toJson();
}

extension CartProperties on Cart {
  Cart updateWith(CartData data) {
    return Cart(id: id, timestamp: data.timestamp, userId: userId);
  }
}

@JsonSerializable(anyMap: true, explicitToJson: true)
class CartItemData {
  factory CartItemData.fromJson(Map json) => _$CartItemDataFromJson(json);

  const CartItemData({required this.amount});

  @JsonKey(name: 'amount', required: true, disallowNullValue: true)
  final int amount;

  Map<String, Object?> toJson() => _$CartItemDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class CartItem extends CartItemData implements _CartItem {
  factory CartItem.fromJson(String id, Map json) =>
      _$CartItemFromJson({...json, '_id': id});

  const CartItem({
    required this.id,
    required super.amount,
    required this.productId,
    required this.cartId,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'product-id', required: true, disallowNullValue: true)
  final String productId;

  @override
  @JsonKey(name: 'cart-id', required: true, disallowNullValue: true)
  final String cartId;

  @override
  Map<String, Object?> toJson() {
    return {..._$CartItemToJson(this)..remove('_id')};
  }
}

class CartItemDependency extends Dependency<CartItemData> {
  CartItemDependency({required this.productId, required this.cartId})
    : super.weak([productId, cartId]);

  final String productId;

  final String cartId;
}

class CartItemFields {
  const CartItemFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema amount = const FieldSchema(
    fieldName: 'amount',
    columnName: 'amount',
  );

  final ForeignKeySchema productId = const ForeignKeySchema(
    fieldName: 'productId',
    columnName: 'product-id',
    targetTableName: 'Products',
    targetColumnName: 'id',
    unique: false,
  );

  final ForeignKeySchema cartId = const ForeignKeySchema(
    fieldName: 'cartId',
    columnName: 'cart-id',
    targetTableName: 'Carts',
    targetColumnName: 'id',
    unique: false,
  );
}

class CartItemEntity implements Entity<CartItemData, CartItem, String> {
  const CartItemEntity();

  static const CartItemFields fields = CartItemFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'CartItems',
    primaryKey: fields.id,
    fields: [fields.amount, fields.productId, fields.cartId],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  CartItem fromData(
    CartItemDependency dependency,
    String id,
    CartItemData data,
  ) {
    return CartItem(
      id: id,
      amount: data.amount,
      productId: dependency.productId,
      cartId: dependency.cartId,
    );
  }

  @override
  CartItem convert(CartItem model, CartItemData data) => model.updateWith(data);

  @override
  CartItem fromJson(String id, Map json) => CartItem.fromJson(id, json);

  @override
  String identify(CartItem model) => model.id;

  @override
  Map<String, Object?> toJson(CartItemData data) => data.toJson();
}

extension CartItemProperties on CartItem {
  CartItem updateWith(CartItemData data) {
    return CartItem(
      id: id,
      amount: data.amount,
      productId: productId,
      cartId: cartId,
    );
  }
}

@JsonSerializable(anyMap: true, explicitToJson: true, constructor: '_')
class ReviewData {
  factory ReviewData.fromJson(Map json) => _$ReviewDataFromJson(json);

  factory ReviewData._({
    required String text,
    required DateTime timestamp,
    required ReviewContentType type,
    required Map content,
  }) {
    return ReviewData(
      text: text,
      timestamp: timestamp,
      type: type,
      content: ReviewContent.fromType(type, content),
    );
  }

  const ReviewData({
    required this.text,
    required this.timestamp,
    required this.type,
    required this.content,
  });

  @JsonKey(name: 'text', required: true, disallowNullValue: true)
  final String text;

  @JsonKey(name: 'timestamp', required: true, disallowNullValue: true)
  final DateTime timestamp;

  @JsonKey(name: 'type', required: true, disallowNullValue: true)
  final ReviewContentType type;

  @JsonKey(name: 'content', required: true, disallowNullValue: true)
  final ReviewContent content;

  Map<String, Object?> toJson() => _$ReviewDataToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true, constructor: '_')
@CopyWith(skipFields: true)
class Review extends ReviewData implements _Review {
  factory Review.fromJson(String id, Map json) =>
      _$ReviewFromJson({...json, '_id': id});

  factory Review._({
    required String id,
    required String text,
    required DateTime timestamp,
    required ReviewContentType type,
    required Map content,
    required String userId,
  }) {
    final ReviewData data = ReviewData._(
      text: text,
      timestamp: timestamp,
      type: type,
      content: content,
    );
    return Review(
      id: id,
      text: data.text,
      timestamp: data.timestamp,
      type: data.type,
      content: data.content,
      userId: userId,
    );
  }

  const Review({
    required this.id,
    required super.text,
    required super.timestamp,
    required super.type,
    required super.content,
    required this.userId,
  });

  @JsonKey(name: '_id', required: true, disallowNullValue: true)
  final String id;

  @override
  @JsonKey(name: 'user-id', required: true, disallowNullValue: true)
  final String userId;

  @override
  String get _qUserIdType => [userId, $normalizeEnum(type)].join('_');

  @override
  Map<String, Object?> toJson() {
    return {..._$ReviewToJson(this)..remove('_id'), '_q-type': _qUserIdType};
  }
}

class ReviewDependency extends Dependency<ReviewData> {
  ReviewDependency({required this.userId}) : super.weak([userId]);

  final String userId;
}

class ReviewFields {
  const ReviewFields();

  final FieldSchema id = const FieldSchema(fieldName: 'id', columnName: 'id');

  final FieldSchema text = const FieldSchema(
    fieldName: 'text',
    columnName: 'text',
  );

  final FieldSchema timestamp = const FieldSchema(
    fieldName: 'timestamp',
    columnName: 'timestamp',
  );

  final FieldSchema type = const FieldSchema(
    fieldName: 'type',
    columnName: 'type',
  );

  final FieldSchema content = const FieldSchema(
    fieldName: 'content',
    columnName: 'content',
  );

  final ForeignKeySchema userId = const ForeignKeySchema(
    fieldName: 'userId',
    columnName: 'user-id',
    targetTableName: 'Users',
    targetColumnName: 'id',
    unique: false,
  );
}

class ReviewEntity implements Entity<ReviewData, Review, String> {
  const ReviewEntity();

  static const ReviewFields fields = ReviewFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'Reviews',
    primaryKey: fields.id,
    fields: [
      fields.text,
      fields.timestamp,
      fields.type,
      fields.content,
      fields.userId,
    ],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  Review fromData(ReviewDependency dependency, String id, ReviewData data) {
    return Review(
      id: id,
      text: data.text,
      timestamp: data.timestamp,
      type: data.type,
      content: data.content,
      userId: dependency.userId,
    );
  }

  @override
  Review convert(Review model, ReviewData data) => model.updateWith(data);

  @override
  Review fromJson(String id, Map json) => Review.fromJson(id, json);

  @override
  String identify(Review model) => model.id;

  @override
  Map<String, Object?> toJson(ReviewData data) => data.toJson();
}

extension ReviewProperties on Review {
  Review updateWith(ReviewData data) {
    return Review(
      id: id,
      text: data.text,
      timestamp: data.timestamp,
      type: data.type,
      content: data.content,
      userId: userId,
    );
  }
}

enum ReviewContentType { product, service, user }

abstract class ReviewContent implements _ReviewContent {
  factory ReviewContent.fromType(ReviewContentType type, Map json) {
    switch (type) {
      case ReviewContentType.product:
        return ProductReviewContent.fromJson(json);
      case ReviewContentType.service:
        return ServiceReviewContent.fromJson(json);
      case ReviewContentType.user:
        return UserReviewContent.fromJson(json);
    }
  }

  ReviewContentType get type;
  Map<String, Object?> toJson();
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class ProductReviewContent implements ReviewContent, _ProductReviewContent {
  factory ProductReviewContent.fromJson(Map json) =>
      _$ProductReviewContentFromJson(json);

  const ProductReviewContent({required this.rating});

  @override
  @JsonKey(name: 'rating', required: true, disallowNullValue: true)
  final int rating;

  @override
  final ReviewContentType type = ReviewContentType.product;

  @override
  Map<String, Object?> toJson() => _$ProductReviewContentToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class ServiceReviewContent implements ReviewContent, _ServiceReviewContent {
  factory ServiceReviewContent.fromJson(Map json) =>
      _$ServiceReviewContentFromJson(json);

  const ServiceReviewContent({required this.rating});

  @override
  @JsonKey(name: 'satisfaction', required: true, disallowNullValue: true)
  final ReviewSatisfaction rating;

  @override
  final ReviewContentType type = ReviewContentType.service;

  @override
  Map<String, Object?> toJson() => _$ServiceReviewContentToJson(this);
}

@JsonSerializable(anyMap: true, explicitToJson: true)
@CopyWith(skipFields: true)
class UserReviewContent implements ReviewContent, _UserReviewContent {
  factory UserReviewContent.fromJson(Map json) =>
      _$UserReviewContentFromJson(json);

  const UserReviewContent({required this.userId});

  @override
  @JsonKey(name: 'user-id', required: true, disallowNullValue: true)
  final String userId;

  @override
  final ReviewContentType type = ReviewContentType.user;

  @override
  Map<String, Object?> toJson() => _$UserReviewContentToJson(this);
}

class Dorm {
  const Dorm(this._engine);

  final BaseEngine<Query> _engine;

  DatabaseEntity<UserData, User, String, Query> get users =>
      DatabaseEntity(const UserEntity(), engine: _engine);

  DatabaseEntity<ProductData, Product, String, Query> get products =>
      DatabaseEntity(const ProductEntity(), engine: _engine);

  DatabaseEntity<CartData, Cart, String, Query> get carts =>
      DatabaseEntity(const CartEntity(), engine: _engine);

  DatabaseEntity<CartItemData, CartItem, String, Query> get cartItems =>
      DatabaseEntity(const CartItemEntity(), engine: _engine);

  DatabaseEntity<ReviewData, Review, String, Query> get reviews =>
      DatabaseEntity(const ReviewEntity(), engine: _engine);

  DormRelations get relations => DormRelations(this);
}

class DormRelations {
  const DormRelations(this._dorm);
  final Dorm _dorm;
  RelationPath<Dorm, User, User, Query> get users =>
      RelationPath.root(_dorm.users.repository, context: _dorm);
  RelationPath<Dorm, Product, Product, Query> get products =>
      RelationPath.root(_dorm.products.repository, context: _dorm);
  RelationPath<Dorm, Cart, Cart, Query> get carts =>
      RelationPath.root(_dorm.carts.repository, context: _dorm);
  RelationPath<Dorm, CartItem, CartItem, Query> get cartItems =>
      RelationPath.root(_dorm.cartItems.repository, context: _dorm);
  RelationPath<Dorm, Review, Review, Query> get reviews =>
      RelationPath.root(_dorm.reviews.repository, context: _dorm);
}

extension UserRelationPaths<Root> on RelationPath<Dorm, Root, User, Query> {
  RelationPath<Dorm, Root, Cart, Query> get carts {
    return toMany(
      context.carts.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: CartEntity.fields.userId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: CartEntity.fields.userId),
    );
  }

  RelationPath<Dorm, Root, List<Cart>, Query> get cartsOrEmpty {
    return toManyOrEmpty(
      context.carts.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: CartEntity.fields.userId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: CartEntity.fields.userId),
    );
  }

  RelationPath<Dorm, Root, Review, Query> get reviews {
    return toMany(
      context.reviews.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: ReviewEntity.fields.userId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: ReviewEntity.fields.userId),
    );
  }

  RelationPath<Dorm, Root, List<Review>, Query> get reviewsOrEmpty {
    return toManyOrEmpty(
      context.reviews.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: UserEntity.fields.id,
        target: ReviewEntity.fields.userId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: ReviewEntity.fields.userId),
    );
  }
}

extension ProductRelationPaths<Root>
    on RelationPath<Dorm, Root, Product, Query> {
  RelationPath<Dorm, Root, CartItem, Query> get cartItems {
    return toMany(
      context.cartItems.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: ProductEntity.fields.id,
        target: CartItemEntity.fields.productId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: CartItemEntity.fields.productId),
    );
  }

  RelationPath<Dorm, Root, List<CartItem>, Query> get cartItemsOrEmpty {
    return toManyOrEmpty(
      context.cartItems.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: ProductEntity.fields.id,
        target: CartItemEntity.fields.productId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: CartItemEntity.fields.productId),
    );
  }
}

extension CartRelationPaths<Root> on RelationPath<Dorm, Root, Cart, Query> {
  RelationPath<Dorm, Root, User, Query> get user {
    return toOne(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: CartEntity.fields.userId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.userId,
    );
  }

  RelationPath<Dorm, Root, User?, Query> get userOrNull {
    return toOneOrNull(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: CartEntity.fields.userId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.userId,
    );
  }

  RelationPath<Dorm, Root, CartItem, Query> get items {
    return toMany(
      context.cartItems.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: CartEntity.fields.id,
        target: CartItemEntity.fields.cartId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: CartItemEntity.fields.cartId),
    );
  }

  RelationPath<Dorm, Root, List<CartItem>, Query> get itemsOrEmpty {
    return toManyOrEmpty(
      context.cartItems.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.many,
        source: CartEntity.fields.id,
        target: CartItemEntity.fields.cartId,
      ),
      on: (model) =>
          BaseFilter.value(model.id, field: CartItemEntity.fields.cartId),
    );
  }
}

extension CartItemRelationPaths<Root>
    on RelationPath<Dorm, Root, CartItem, Query> {
  RelationPath<Dorm, Root, Product, Query> get product {
    return toOne(
      context.products.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: CartItemEntity.fields.productId,
        target: ProductEntity.fields.id,
      ),
      on: (model) => model.productId,
    );
  }

  RelationPath<Dorm, Root, Product?, Query> get productOrNull {
    return toOneOrNull(
      context.products.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: CartItemEntity.fields.productId,
        target: ProductEntity.fields.id,
      ),
      on: (model) => model.productId,
    );
  }

  RelationPath<Dorm, Root, Cart, Query> get cart {
    return toOne(
      context.carts.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: CartItemEntity.fields.cartId,
        target: CartEntity.fields.id,
      ),
      on: (model) => model.cartId,
    );
  }

  RelationPath<Dorm, Root, Cart?, Query> get cartOrNull {
    return toOneOrNull(
      context.carts.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: CartItemEntity.fields.cartId,
        target: CartEntity.fields.id,
      ),
      on: (model) => model.cartId,
    );
  }
}

extension ReviewRelationPaths<Root> on RelationPath<Dorm, Root, Review, Query> {
  RelationPath<Dorm, Root, User, Query> get user {
    return toOne(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: ReviewEntity.fields.userId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.userId,
    );
  }

  RelationPath<Dorm, Root, User?, Query> get userOrNull {
    return toOneOrNull(
      context.users.repository,
      spec: RelationSpec(
        cardinality: RelationCardinality.one,
        source: ReviewEntity.fields.userId,
        target: UserEntity.fields.id,
      ),
      on: (model) => model.userId,
    );
  }
}
