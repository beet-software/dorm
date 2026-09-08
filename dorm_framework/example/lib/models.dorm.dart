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

  final DerivedFieldSchema qUsername = const DerivedFieldSchema(
    fieldName: '_qUsername',
    columnName: '_q-username',
    path: ['_q-username'],
    storageName: '_q-username',
  );
}

class UserEntity
    implements
        Entity<UserData, User, String, SimpleCreation<UserData, String>> {
  const UserEntity();

  static const UserFields fields = UserFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'Users',
    primaryKeys: [fields.id],
    fields: [fields.username, fields.email, fields.profile],
    derivedFields: [fields.qUsername],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.engine;

  @override
  User fromData(ResolvedCreation<UserData, String> creation) {
    return User(
      id: creation.id,
      username: creation.data.username,
      email: creation.data.email,
      profile: creation.data.profile,
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

  final DerivedFieldSchema qName = const DerivedFieldSchema(
    fieldName: '_qName',
    columnName: '_q-name',
    path: ['_q-name'],
    storageName: '_q-name',
  );
}

class ProductEntity
    implements
        Entity<
          ProductData,
          Product,
          String,
          SimpleCreation<ProductData, String>
        > {
  const ProductEntity();

  static const ProductFields fields = ProductFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'Products',
    primaryKeys: [fields.id],
    fields: [fields.name, fields.description, fields.price],
    derivedFields: [fields.qName],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.engine;

  @override
  Product fromData(ResolvedCreation<ProductData, String> creation) {
    return Product(
      id: creation.id,
      name: creation.data.name,
      description: creation.data.description,
      price: creation.data.price,
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

class CartEntity
    implements
        Entity<CartData, Cart, String, SimpleCreation<CartData, String>> {
  const CartEntity();

  static const CartFields fields = CartFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'Carts',
    primaryKeys: [fields.id],
    fields: [fields.timestamp, fields.userId],
    derivedFields: [],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.engine;

  @override
  Cart fromData(ResolvedCreation<CartData, String> creation) {
    return Cart(
      id: creation.identitySource == CreationIdentitySource.generated
          ? _Cart.$dorm$generateId(
              _$Cart.fromData(
                creation.dependency as CartDependency,
                creation.data,
              ),
              creation.id,
            )
          : creation.id,
      timestamp: creation.data.timestamp,
      userId: (creation.dependency as CartDependency).userId,
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

class CartItemEntity
    implements
        Entity<
          CartItemData,
          CartItem,
          String,
          SimpleCreation<CartItemData, String>
        > {
  const CartItemEntity();

  static const CartItemFields fields = CartItemFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'CartItems',
    primaryKeys: [fields.id],
    fields: [fields.amount, fields.productId, fields.cartId],
    derivedFields: [],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.engine;

  @override
  CartItem fromData(ResolvedCreation<CartItemData, String> creation) {
    return CartItem(
      id: creation.id,
      amount: creation.data.amount,
      productId: (creation.dependency as CartItemDependency).productId,
      cartId: (creation.dependency as CartItemDependency).cartId,
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

  final DerivedFieldSchema qUserIdType = const DerivedFieldSchema(
    fieldName: '_qUserIdType',
    columnName: '_q-type',
    path: ['_q-type'],
    storageName: '_q-type',
  );
}

class ReviewEntity
    implements
        Entity<ReviewData, Review, String, SimpleCreation<ReviewData, String>> {
  const ReviewEntity();

  static const ReviewFields fields = ReviewFields();

  static final EntitySchema _schema = EntitySchema(
    tableName: 'Reviews',
    primaryKeys: [fields.id],
    fields: [
      fields.text,
      fields.timestamp,
      fields.type,
      fields.content,
      fields.userId,
    ],
    derivedFields: [fields.qUserIdType],
  );

  @override
  EntitySchema get schema => _schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  IdentityGenerationStrategy get identityGeneration =>
      IdentityGenerationStrategy.engine;

  @override
  Review fromData(ResolvedCreation<ReviewData, String> creation) {
    return Review(
      id: creation.id,
      text: creation.data.text,
      timestamp: creation.data.timestamp,
      type: creation.data.type,
      content: creation.data.content,
      userId: (creation.dependency as ReviewDependency).userId,
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

class Dorm<Q extends BaseQuery<Q>, P extends PageRequest> {
  const Dorm(this._engine);

  final BaseEngine<Q, P> _engine;

  DatabaseEntity<UserData, User, String, Q, SimpleCreation<UserData, String>, P>
  get users => DatabaseEntity(const UserEntity(), engine: _engine);

  DatabaseEntity<
    ProductData,
    Product,
    String,
    Q,
    SimpleCreation<ProductData, String>,
    P
  >
  get products => DatabaseEntity(const ProductEntity(), engine: _engine);

  DatabaseEntity<CartData, Cart, String, Q, SimpleCreation<CartData, String>, P>
  get carts => DatabaseEntity(const CartEntity(), engine: _engine);

  DatabaseEntity<
    CartItemData,
    CartItem,
    String,
    Q,
    SimpleCreation<CartItemData, String>,
    P
  >
  get cartItems => DatabaseEntity(const CartItemEntity(), engine: _engine);

  DatabaseEntity<
    ReviewData,
    Review,
    String,
    Q,
    SimpleCreation<ReviewData, String>,
    P
  >
  get reviews => DatabaseEntity(const ReviewEntity(), engine: _engine);

  DormRelations<Q, P> get relations => DormRelations<Q, P>(this);
}

class TransactionalDorm<Q extends BaseQuery<Q>, P extends PageRequest>
    extends Dorm<Q, P> {
  const TransactionalDorm(this._transactionalEngine)
    : super(_transactionalEngine);

  final TransactionalEngine<Q, P> _transactionalEngine;

  Future<T> transaction<T>(Future<T> Function(Dorm<Q, P>) action) =>
      _transactionalEngine.transaction((engine) => action(Dorm<Q, P>(engine)));
}

class DormRelations<Q extends BaseQuery<Q>, P extends PageRequest> {
  const DormRelations(this._dorm);

  final Dorm<Q, P> _dorm;

  RelationPath<Dorm<Q, P>, User, User, Q> get users =>
      RelationPath.root(_dorm.users.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, Product, Product, Q> get products =>
      RelationPath.root(_dorm.products.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, Cart, Cart, Q> get carts =>
      RelationPath.root(_dorm.carts.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, CartItem, CartItem, Q> get cartItems =>
      RelationPath.root(_dorm.cartItems.repository, context: _dorm);

  RelationPath<Dorm<Q, P>, Review, Review, Q> get reviews =>
      RelationPath.root(_dorm.reviews.repository, context: _dorm);
}

extension UserRelationPaths<Root, Q extends BaseQuery<Q>, P extends PageRequest>
    on RelationPath<Dorm<Q, P>, Root, User, Q> {
  RelationPath<Dorm<Q, P>, Root, Cart, Q> get carts {
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

  RelationPath<Dorm<Q, P>, Root, List<Cart>, Q> get cartsOrEmpty {
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

  RelationPath<Dorm<Q, P>, Root, Review, Q> get reviews {
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

  RelationPath<Dorm<Q, P>, Root, List<Review>, Q> get reviewsOrEmpty {
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

extension ProductRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, Product, Q> {
  RelationPath<Dorm<Q, P>, Root, CartItem, Q> get cartItems {
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

  RelationPath<Dorm<Q, P>, Root, List<CartItem>, Q> get cartItemsOrEmpty {
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

extension CartRelationPaths<Root, Q extends BaseQuery<Q>, P extends PageRequest>
    on RelationPath<Dorm<Q, P>, Root, Cart, Q> {
  RelationPath<Dorm<Q, P>, Root, User, Q> get user {
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

  RelationPath<Dorm<Q, P>, Root, User?, Q> get userOrNull {
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

  RelationPath<Dorm<Q, P>, Root, CartItem, Q> get items {
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

  RelationPath<Dorm<Q, P>, Root, List<CartItem>, Q> get itemsOrEmpty {
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

extension CartItemRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, CartItem, Q> {
  RelationPath<Dorm<Q, P>, Root, Product, Q> get product {
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

  RelationPath<Dorm<Q, P>, Root, Product?, Q> get productOrNull {
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

  RelationPath<Dorm<Q, P>, Root, Cart, Q> get cart {
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

  RelationPath<Dorm<Q, P>, Root, Cart?, Q> get cartOrNull {
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

extension ReviewRelationPaths<
  Root,
  Q extends BaseQuery<Q>,
  P extends PageRequest
>
    on RelationPath<Dorm<Q, P>, Root, Review, Q> {
  RelationPath<Dorm<Q, P>, Root, User, Q> get user {
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

  RelationPath<Dorm<Q, P>, Root, User?, Q> get userOrNull {
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
