// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// OrmGenerator
// **************************************************************************

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Profile {
  factory Profile.fromJson(Map json) => _$ProfileFromJson(json);

  const Profile({
    required this.name,
    required this.birthDate,
    required this.bio,
  });

  @JsonKey(
    name: 'name',
    required: true,
    disallowNullValue: true,
  )
  final String name;

  @JsonKey(
    name: 'birth-date',
    required: true,
    disallowNullValue: true,
  )
  final DateTime birthDate;

  @JsonKey(name: 'bio')
  final String? bio;

  Map<String, Object?> toJson() => _$ProfileToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class UserData {
  factory UserData.fromJson(Map json) => _$UserDataFromJson(json);

  const UserData({
    required this.username,
    required this.email,
    required this.profile,
  });

  @JsonKey(
    name: 'username',
    required: true,
    disallowNullValue: true,
  )
  final String username;

  @JsonKey(
    name: 'email',
    required: true,
    disallowNullValue: true,
  )
  final String email;

  @JsonKey(
    name: 'profile',
    required: true,
    disallowNullValue: true,
  )
  final Profile profile;

  Map<String, Object?> toJson() => _$UserDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class User extends UserData implements _User {
  factory User.fromJson(
    String id,
    Map json,
  ) =>
      _$UserFromJson({
        ...json,
        '_id': id,
      });

  const User({
    required this.id,
    required super.username,
    required super.email,
    required super.profile,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  String get _qUsername => [$normalizeText(username)].join('_');
  @override
  Map<String, Object?> toJson() {
    return {
      ..._$UserToJson(this)..remove('_id'),
      '_q-username': _qUsername,
    };
  }
}

class UserDependency extends Dependency<UserData> {
  const UserDependency() : super.strong();
}

class UserEntity implements Entity<UserData, User> {
  const UserEntity();

  @override
  final String tableName = 'Users';

  @override
  User fromData(
    UserDependency dependency,
    String id,
    UserData data,
  ) {
    return User(
      id: id,
      username: data.username,
      email: data.email,
      profile: data.profile,
    );
  }

  @override
  User convert(
    User model,
    UserData data,
  ) {
    return User(
      id: model.id,
      username: data.username,
      email: data.email,
      profile: data.profile,
    );
  }

  @override
  User fromJson(
    String id,
    Map json,
  ) =>
      User.fromJson(
        id,
        json,
      );
  @override
  String identify(User model) => model.id;
  @override
  Map<String, Object?> toJson(UserData data) => data.toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class ProductData {
  factory ProductData.fromJson(Map json) => _$ProductDataFromJson(json);

  const ProductData({
    required this.name,
    required this.description,
    required this.price,
  });

  @JsonKey(
    name: 'name',
    required: true,
    disallowNullValue: true,
  )
  final String name;

  @JsonKey(
    name: 'description',
    required: true,
    disallowNullValue: true,
  )
  final String description;

  @JsonKey(
    name: 'price',
    required: true,
    disallowNullValue: true,
  )
  final Decimal price;

  Map<String, Object?> toJson() => _$ProductDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Product extends ProductData implements _Product {
  factory Product.fromJson(
    String id,
    Map json,
  ) =>
      _$ProductFromJson({
        ...json,
        '_id': id,
      });

  const Product({
    required this.id,
    required super.name,
    required super.description,
    required super.price,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  String get _qName => [$normalizeText(name)].join('_');
  @override
  Map<String, Object?> toJson() {
    return {
      ..._$ProductToJson(this)..remove('_id'),
      '_q-name': _qName,
    };
  }
}

class ProductDependency extends Dependency<ProductData> {
  const ProductDependency() : super.strong();
}

class ProductEntity implements Entity<ProductData, Product> {
  const ProductEntity();

  @override
  final String tableName = 'Products';

  @override
  Product fromData(
    ProductDependency dependency,
    String id,
    ProductData data,
  ) {
    return Product(
      id: id,
      name: data.name,
      description: data.description,
      price: data.price,
    );
  }

  @override
  Product convert(
    Product model,
    ProductData data,
  ) {
    return Product(
      id: model.id,
      name: data.name,
      description: data.description,
      price: data.price,
    );
  }

  @override
  Product fromJson(
    String id,
    Map json,
  ) =>
      Product.fromJson(
        id,
        json,
      );
  @override
  String identify(Product model) => model.id;
  @override
  Map<String, Object?> toJson(ProductData data) => data.toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class CartData {
  factory CartData.fromJson(Map json) => _$CartDataFromJson(json);

  const CartData({required this.timestamp});

  @JsonKey(
    name: 'timestamp',
    required: true,
    disallowNullValue: true,
  )
  final DateTime timestamp;

  Map<String, Object?> toJson() => _$CartDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class Cart extends CartData implements _Cart {
  factory Cart.fromJson(
    String id,
    Map json,
  ) =>
      _$CartFromJson({
        ...json,
        '_id': id,
      });

  const Cart({
    required this.id,
    required super.timestamp,
    required this.userId,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  @JsonKey(
    name: 'user-id',
    required: true,
    disallowNullValue: true,
  )
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

class CartEntity implements Entity<CartData, Cart> {
  const CartEntity();

  @override
  final String tableName = 'Carts';

  @override
  Cart fromData(
    CartDependency dependency,
    String id,
    CartData data,
  ) {
    return Cart(
      id: dependency.userId,
      timestamp: data.timestamp,
      userId: dependency.userId,
    );
  }

  @override
  Cart convert(
    Cart model,
    CartData data,
  ) {
    return Cart(
      id: model.id,
      timestamp: data.timestamp,
      userId: model.userId,
    );
  }

  @override
  Cart fromJson(
    String id,
    Map json,
  ) =>
      Cart.fromJson(
        id,
        json,
      );
  @override
  String identify(Cart model) => model.id;
  @override
  Map<String, Object?> toJson(CartData data) => data.toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class CartItemData {
  factory CartItemData.fromJson(Map json) => _$CartItemDataFromJson(json);

  const CartItemData({required this.amount});

  @JsonKey(
    name: 'amount',
    required: true,
    disallowNullValue: true,
  )
  final int amount;

  Map<String, Object?> toJson() => _$CartItemDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class CartItem extends CartItemData implements _CartItem {
  factory CartItem.fromJson(
    String id,
    Map json,
  ) =>
      _$CartItemFromJson({
        ...json,
        '_id': id,
      });

  const CartItem({
    required this.id,
    required super.amount,
    required this.productId,
    required this.cartId,
  });

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  @JsonKey(
    name: 'product-id',
    required: true,
    disallowNullValue: true,
  )
  final String productId;

  @override
  @JsonKey(
    name: 'cart-id',
    required: true,
    disallowNullValue: true,
  )
  final String cartId;

  @override
  Map<String, Object?> toJson() {
    return {..._$CartItemToJson(this)..remove('_id')};
  }
}

class CartItemDependency extends Dependency<CartItemData> {
  CartItemDependency({
    required this.productId,
    required this.cartId,
  }) : super.weak([
          productId,
          cartId,
        ]);

  final String productId;

  final String cartId;
}

class CartItemEntity implements Entity<CartItemData, CartItem> {
  const CartItemEntity();

  @override
  final String tableName = 'CartItems';

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
  CartItem convert(
    CartItem model,
    CartItemData data,
  ) {
    return CartItem(
      id: model.id,
      amount: data.amount,
      productId: model.productId,
      cartId: model.cartId,
    );
  }

  @override
  CartItem fromJson(
    String id,
    Map json,
  ) =>
      CartItem.fromJson(
        id,
        json,
      );
  @override
  String identify(CartItem model) => model.id;
  @override
  Map<String, Object?> toJson(CartItemData data) => data.toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
  constructor: '_',
)
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
      content: ReviewContent.fromType(
        type,
        content,
      ),
    );
  }

  const ReviewData({
    required this.text,
    required this.timestamp,
    required this.content,
    required this.type,
  });

  @JsonKey(
    name: 'text',
    required: true,
    disallowNullValue: true,
  )
  final String text;

  @JsonKey(
    name: 'timestamp',
    required: true,
    disallowNullValue: true,
  )
  final DateTime timestamp;

  @JsonKey(
    name: 'type',
    required: true,
    disallowNullValue: true,
  )
  final ReviewContentType type;

  @JsonKey(
    name: 'content',
    required: true,
    disallowNullValue: true,
  )
  final ReviewContent content;

  Map<String, Object?> toJson() => _$ReviewDataToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
  constructor: '_',
)
class Review extends ReviewData implements _Review {
  factory Review.fromJson(
    String id,
    Map json,
  ) =>
      _$ReviewFromJson({
        ...json,
        '_id': id,
      });

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

  @JsonKey(
    name: '_id',
    required: true,
    disallowNullValue: true,
  )
  final String id;

  @override
  @JsonKey(
    name: 'user-id',
    required: true,
    disallowNullValue: true,
  )
  final String userId;

  @override
  String get _qUserIdType => [
        userId,
        $normalizeEnum(type),
      ].join('_');
  @override
  Map<String, Object?> toJson() {
    return {
      ..._$ReviewToJson(this)..remove('_id'),
      '_q-type': _qUserIdType,
    };
  }
}

class ReviewDependency extends Dependency<ReviewData> {
  ReviewDependency({required this.userId}) : super.weak([userId]);

  final String userId;
}

class ReviewEntity implements Entity<ReviewData, Review> {
  const ReviewEntity();

  @override
  final String tableName = 'Reviews';

  @override
  Review fromData(
    ReviewDependency dependency,
    String id,
    ReviewData data,
  ) {
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
  Review convert(
    Review model,
    ReviewData data,
  ) {
    return Review(
      id: model.id,
      text: data.text,
      timestamp: data.timestamp,
      type: data.type,
      content: data.content,
      userId: model.userId,
    );
  }

  @override
  Review fromJson(
    String id,
    Map json,
  ) =>
      Review.fromJson(
        id,
        json,
      );
  @override
  String identify(Review model) => model.id;
  @override
  Map<String, Object?> toJson(ReviewData data) => data.toJson();
}

enum ReviewContentType { product, service, user }

abstract class ReviewContent implements _ReviewContent {
  factory ReviewContent.fromType(
    ReviewContentType type,
    Map json,
  ) {
    switch (type) {
      case ReviewContentType.product:
        return ProductReviewContent.fromJson(json);
      case ReviewContentType.service:
        return ServiceReviewContent.fromJson(json);
      case ReviewContentType.user:
        return UserReviewContent.fromJson(json);
    }
  }

  const ReviewContent._();

  ReviewContentType get type;
  Map<String, Object?> toJson();
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class ProductReviewContent extends ReviewContent
    implements _ProductReviewContent {
  factory ProductReviewContent.fromJson(Map json) =>
      _$ProductReviewContentFromJson(json);

  const ProductReviewContent({required this.rating}) : super._();

  @override
  @JsonKey(
    name: 'rating',
    required: true,
    disallowNullValue: true,
  )
  final int rating;

  @override
  final ReviewContentType type = ReviewContentType.product;

  @override
  Map<String, Object?> toJson() => _$ProductReviewContentToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class ServiceReviewContent extends ReviewContent
    implements _ServiceReviewContent {
  factory ServiceReviewContent.fromJson(Map json) =>
      _$ServiceReviewContentFromJson(json);

  const ServiceReviewContent({required this.rating}) : super._();

  @override
  @JsonKey(
    name: 'satisfaction',
    required: true,
    disallowNullValue: true,
  )
  final ReviewSatisfaction rating;

  @override
  final ReviewContentType type = ReviewContentType.service;

  @override
  Map<String, Object?> toJson() => _$ServiceReviewContentToJson(this);
}

@JsonSerializable(
  anyMap: true,
  explicitToJson: true,
)
class UserReviewContent extends ReviewContent implements _UserReviewContent {
  factory UserReviewContent.fromJson(Map json) =>
      _$UserReviewContentFromJson(json);

  const UserReviewContent({required this.userId}) : super._();

  @override
  @JsonKey(
    name: 'user-id',
    required: true,
    disallowNullValue: true,
  )
  final String userId;

  @override
  final ReviewContentType type = ReviewContentType.user;

  @override
  Map<String, Object?> toJson() => _$UserReviewContentToJson(this);
}

class Dorm {
  const Dorm(this._root);

  final BaseReference _root;

  DatabaseEntity<UserData, User> get users => DatabaseEntity(
        const UserEntity(),
        reference: _root,
      );
  DatabaseEntity<ProductData, Product> get products => DatabaseEntity(
        const ProductEntity(),
        reference: _root,
      );
  DatabaseEntity<CartData, Cart> get carts => DatabaseEntity(
        const CartEntity(),
        reference: _root,
      );
  DatabaseEntity<CartItemData, CartItem> get cartItems => DatabaseEntity(
        const CartItemEntity(),
        reference: _root,
      );
  DatabaseEntity<ReviewData, Review> get reviews => DatabaseEntity(
        const ReviewEntity(),
        reference: _root,
      );
}
