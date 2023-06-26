import 'dart:async';

import 'package:dorm/dorm.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mock;
import 'package:test/test.dart';

import 'relationships_test.mocks.dart';

abstract class Customer {
  String get id;

  String get name;

  String get email;
}

abstract class Order {
  String get id;

  DateTime get date;

  double get amount;

  String get customerId;
}

abstract class Item {
  String get id;

  String get orderId;

  String get productId;

  int get quantity;
}

abstract class Product {
  String get id;

  String get name;
}

@GenerateNiceMocks([
  MockSpec<Customer>(),
  MockSpec<Order>(),
  MockSpec<Product>(),
  MockSpec<Item>(),
  MockSpec<Readable>(),
])
void main() {
  late MockReadable<Customer> customersMock;
  late MockReadable<Order> ordersMock;
  late MockReadable<Product> productsMock;
  late MockReadable<Item> itemsMock;
  late MockCustomer c1;
  late MockCustomer c2;
  late MockCustomer c3;
  late MockProduct p1;
  late MockProduct p2;
  late MockProduct p3;

  void setUpMockCustomer(MockCustomer customer, String id) {
    mock.when(customer.id).thenReturn(id);
    mock.when(customersMock.peek(id)).thenAnswer((_) async => customer);
    mock.when(customersMock.pull(id)).thenAnswer((_) => Stream.value(customer));
  }

  void setUpMockProduct(MockProduct product, String id) {
    mock.when(product.id).thenReturn(id);
    mock.when(productsMock.peek(id)).thenAnswer((_) async => product);
    mock.when(productsMock.pull(id)).thenAnswer((_) => Stream.value(product));
  }

  void setUpMockOrder(MockOrder order, String id, [String? customerId]) {
    mock.when(order.id).thenReturn(id);
    mock.when(order.customerId).thenReturn(customerId ?? id);
    mock.when(ordersMock.peek(id)).thenAnswer((_) async => order);
    mock.when(ordersMock.pull(id)).thenAnswer((_) => Stream.value(order));
  }

  void setUpMockItem(
      MockItem item, String id, String orderId, String productId) {
    mock.when(item.id).thenReturn(id);
    mock.when(item.orderId).thenReturn(orderId);
    mock.when(item.productId).thenReturn(productId);
    mock.when(itemsMock.peek(id)).thenAnswer((_) async => item);
    mock.when(itemsMock.pull(id)).thenAnswer((_) => Stream.value(item));
  }

  void setUpMockOrders(List<MockOrder> orders, [Filter? filter]) {
    mock
        .when(ordersMock.pullAll(filter ?? mock.any))
        .thenAnswer((_) => Stream.value(orders));
    mock
        .when(ordersMock.peekAll(filter ?? mock.any))
        .thenAnswer((_) async => orders);
  }

  void setUpMockItems(List<MockItem> items, [Filter? filter]) {
    mock
        .when(itemsMock.pullAll(filter ?? mock.any))
        .thenAnswer((_) => Stream.value(items));
    mock
        .when(itemsMock.peekAll(filter ?? mock.any))
        .thenAnswer((_) async => items);
  }

  setUp(() {
    customersMock = MockReadable();
    ordersMock = MockReadable();
    productsMock = MockReadable();
    itemsMock = MockReadable();

    mock.when(customersMock.peek(mock.any)).thenAnswer((_) async => null);
    mock
        .when(customersMock.pull(mock.any))
        .thenAnswer((_) => Stream.value(null));

    mock.when(ordersMock.peek(mock.any)).thenAnswer((_) async => null);
    mock
        .when(ordersMock.pull(mock.any)) //
        .thenAnswer((_) => Stream.value(null));

    mock.when(productsMock.peek(mock.any)).thenAnswer((_) async => null);
    mock
        .when(productsMock.pull(mock.any)) //
        .thenAnswer((_) => Stream.value(null));

    mock.when(itemsMock.peek(mock.any)).thenAnswer((_) async => null);
    mock
        .when(itemsMock.pull(mock.any)) //
        .thenAnswer((_) => Stream.value(null));

    c1 = MockCustomer();
    setUpMockCustomer(c1, '1');
    mock.when(c1.name).thenReturn('John Doe');
    mock.when(c1.email).thenReturn('john@example.com');

    c2 = MockCustomer();
    setUpMockCustomer(c2, '2');
    mock.when(c2.name).thenReturn('Jane Smith');
    mock.when(c2.email).thenReturn('jane@example.com');

    c3 = MockCustomer();
    setUpMockCustomer(c3, '3');
    mock.when(c3.name).thenReturn('Mark Johnson');
    mock.when(c3.email).thenReturn('mark@example.com');

    p1 = MockProduct();
    setUpMockProduct(p1, '1');
    mock.when(p1.name).thenReturn('Laptop');

    p2 = MockProduct();
    setUpMockProduct(p2, '2');
    mock.when(p2.name).thenReturn('Phone');

    p3 = MockProduct();
    setUpMockProduct(p3, '3');
    mock.when(p3.name).thenReturn('Tablet');

    mock
        .when(customersMock.pullAll(const Filter.empty()))
        .thenAnswer((_) => Stream.value([c1, c2, c3]));
    mock
        .when(customersMock.peekAll(const Filter.empty()))
        .thenAnswer((_) async => [c1, c2, c3]);
    mock
        .when(productsMock.pullAll(const Filter.empty()))
        .thenAnswer((_) => Stream.value([p1, p2, p3]));
    mock
        .when(productsMock.peekAll(const Filter.empty()))
        .thenAnswer((_) async => [p1, p2, p3]);
  });
  tearDown(() {
    mock.resetMockitoState();
  });

  group('one-to-one', () {
    late OneToOneRelationship<Customer, Order> relationship;
    late MockOrder o1;
    late MockOrder o2;
    late MockOrder o4;
    setUp(() {
      relationship = OneToOneRelationship(
        left: customersMock,
        right: ordersMock,
        on: (customer) => customer.id,
      );

      o1 = MockOrder();
      setUpMockOrder(o1, '1');
      mock.when(o1.date).thenReturn(DateTime(2023, 5, 10));
      mock.when(o1.amount).thenReturn(250);

      o2 = MockOrder();
      setUpMockOrder(o2, '2');
      mock.when(o2.date).thenReturn(DateTime(2023, 6, 2));
      mock.when(o2.amount).thenReturn(150);

      o4 = MockOrder();
      setUpMockOrder(o4, '4');
      mock.when(o4.date).thenReturn(DateTime(2023, 6, 20));
      mock.when(o4.amount).thenReturn(75);

      setUpMockOrders([o1, o2, o4]);
    });
    test('peek', () async {
      Join<Customer, Order?>? join;
      join = await relationship.peek('1');
      expect(join?.left.id, '1');
      expect(join?.right?.id, '1');

      join = await relationship.peek('2');
      expect(join?.left.id, '2');
      expect(join?.right?.id, '2');

      join = await relationship.peek('3');
      expect(join?.left.id, '3');
      expect(join?.right?.id, null);

      join = await relationship.peek('4');
      expect(join, isNull);
      expect(join?.left.id, null);
      expect(join?.right?.id, null);
    });
    test('pull', () async {
      Join<Customer, Order?>? join;
      join = await relationship.pull('1').first;
      expect(join?.left.id, '1');
      expect(join?.right?.id, '1');

      join = await relationship.pull('2').first;
      expect(join?.left.id, '2');
      expect(join?.right?.id, '2');

      join = await relationship.pull('3').first;
      expect(join?.left.id, '3');
      expect(join?.right?.id, null);

      join = await relationship.pull('4').first;
      expect(join, isNull);
      expect(join?.left.id, null);
      expect(join?.right?.id, null);
    });
    test('peekAll', () async {
      final List<Join<Customer, Order?>> joins = await relationship.peekAll();
      expect(joins.length, 3);
      Join<Customer, Order?> join;

      join = joins[0];
      expect(join.left.id, '1');
      expect(join.right?.id, '1');

      join = joins[1];
      expect(join.left.id, '2');
      expect(join.right?.id, '2');

      join = joins[2];
      expect(join.left.id, '3');
      expect(join.right?.id, null);
    });
    test('pullAll', () async {
      final List<Join<Customer, Order?>> joins =
          await relationship.pullAll().first;
      expect(joins.length, 3);
      Join<Customer, Order?> join;

      join = joins[0];
      expect(join.left.id, '1');
      expect(join.right?.id, '1');

      join = joins[1];
      expect(join.left.id, '2');
      expect(join.right?.id, '2');

      join = joins[2];
      expect(join.left.id, '3');
      expect(join.right?.id, null);
    });
  });
  group('one-to-many', () {
    late OneToManyRelationship<Customer, Order> relationship;
    late MockOrder o1;
    late MockOrder o2;
    late MockOrder o3;
    late MockOrder o4;
    setUp(() {
      relationship = OneToManyRelationship(
        left: customersMock,
        right: ordersMock,
        on: (customer) => Filter.value(customer.id, key: 'customer-id'),
      );

      o1 = MockOrder();
      setUpMockOrder(o1, '101', '1');
      mock.when(o1.date).thenReturn(DateTime(2023, 5, 10));
      mock.when(o1.amount).thenReturn(250);

      o2 = MockOrder();
      setUpMockOrder(o2, '102', '2');
      mock.when(o2.date).thenReturn(DateTime(2023, 6, 2));
      mock.when(o2.amount).thenReturn(150);

      o3 = MockOrder();
      setUpMockOrder(o3, '103', '1');
      mock.when(o3.date).thenReturn(DateTime(2023, 6, 20));
      mock.when(o3.amount).thenReturn(75);

      o4 = MockOrder();
      setUpMockOrder(o4, '104', '4');
      mock.when(o4.date).thenReturn(DateTime(2023, 6, 21));
      mock.when(o4.amount).thenReturn(200);

      setUpMockOrders([o1, o2, o3, o4], const Filter.empty());
      setUpMockOrders([o1, o3], Filter.value('1', key: 'customer-id'));
      setUpMockOrders([o2], Filter.value('2', key: 'customer-id'));
      setUpMockOrders([], Filter.value('3', key: 'customer-id'));
      setUpMockOrders([o4], Filter.value('4', key: 'customer-id'));
    });
    test('peek', () async {
      Join<Customer, List<Order>>? join;
      join = await relationship.peek('1');
      expect(join?.left.id, '1');
      expect(join?.right.length, 2);
      expect(join?.right[0].id, '101');
      expect(join?.right[0].customerId, '1');
      expect(join?.right[1].id, '103');
      expect(join?.right[1].customerId, '1');

      join = await relationship.peek('2');
      expect(join?.left.id, '2');
      expect(join?.right.length, 1);
      expect(join?.right[0].id, '102');
      expect(join?.right[0].customerId, '2');

      join = await relationship.peek('3');
      expect(join?.left.id, '3');
      expect(join?.right.length, 0);

      join = await relationship.peek('4');
      expect(join, isNull);
      expect(join?.left.id, null);
      expect(join?.right.length, null);
    });
    test('pull', () async {
      Join<Customer, List<Order>>? join;
      join = await relationship.pull('1').first;
      expect(join?.left.id, '1');
      expect(join?.right.length, 2);
      expect(join?.right[0].id, '101');
      expect(join?.right[0].customerId, '1');
      expect(join?.right[1].id, '103');
      expect(join?.right[1].customerId, '1');

      join = await relationship.pull('2').first;
      expect(join?.left.id, '2');
      expect(join?.right.length, 1);
      expect(join?.right[0].id, '102');
      expect(join?.right[0].customerId, '2');

      join = await relationship.pull('3').first;
      expect(join?.left.id, '3');
      expect(join?.right.length, 0);

      join = await relationship.pull('4').first;
      expect(join, isNull);
      expect(join?.left.id, null);
      expect(join?.right.length, null);
    });
    test('peekAll', () async {
      final List<Join<Customer, List<Order>>> joins =
          await relationship.peekAll();
      expect(joins.length, 3);
      Join<Customer, List<Order>> join;

      join = joins[0];
      expect(join, isNotNull);
      expect(join.left.id, '1');
      expect(join.right.length, 2);
      expect(join.right[0].id, '101');
      expect(join.right[0].customerId, '1');
      expect(join.right[1].id, '103');
      expect(join.right[1].customerId, '1');

      join = joins[1];
      expect(join, isNotNull);
      expect(join.left.id, '2');
      expect(join.right.length, 1);
      expect(join.right[0].id, '102');
      expect(join.right[0].customerId, '2');

      join = joins[2];
      expect(join, isNotNull);
      expect(join.left.id, '3');
      expect(join.right.length, 0);
    });
    test('pullAll', () async {
      final List<Join<Customer, List<Order>>> joins =
          await relationship.pullAll().first;
      expect(joins.length, 3);
      Join<Customer, List<Order>> join;

      join = joins[0];
      expect(join.left.id, '1');
      expect(join.right.length, 2);
      expect(join.right[0].id, '101');
      expect(join.right[0].customerId, '1');
      expect(join.right[1].id, '103');
      expect(join.right[1].customerId, '1');

      join = joins[1];
      expect(join.left.id, '2');
      expect(join.right.length, 1);
      expect(join.right[0].id, '102');
      expect(join.right[0].customerId, '2');

      join = joins[2];
      expect(join.left.id, '3');
      expect(join.right.length, 0);
    });
  });
  group('many-to-one', () {
    late ManyToOneRelationship<Order, Customer> relationship;
    late MockOrder o1;
    late MockOrder o2;
    late MockOrder o3;
    late MockOrder o4;
    setUp(() {
      relationship = ManyToOneRelationship(
        left: ordersMock,
        right: customersMock,
        on: (order) => order.customerId,
      );

      o1 = MockOrder();
      setUpMockOrder(o1, '101', '1');
      mock.when(o1.date).thenReturn(DateTime(2023, 5, 10));
      mock.when(o1.amount).thenReturn(250);

      o2 = MockOrder();
      setUpMockOrder(o2, '102', '2');
      mock.when(o2.date).thenReturn(DateTime(2023, 6, 2));
      mock.when(o2.amount).thenReturn(150);

      o3 = MockOrder();
      setUpMockOrder(o3, '103', '1');
      mock.when(o3.date).thenReturn(DateTime(2023, 6, 20));
      mock.when(o3.amount).thenReturn(75);

      o4 = MockOrder();
      setUpMockOrder(o4, '104', '4');
      mock.when(o4.date).thenReturn(DateTime(2023, 6, 21));
      mock.when(o4.amount).thenReturn(200);

      setUpMockOrders([o1, o2, o3, o4], const Filter.empty());
      setUpMockOrders([o1, o3], Filter.value('1', key: 'customer-id'));
      setUpMockOrders([o2], Filter.value('2', key: 'customer-id'));
      setUpMockOrders([], Filter.value('3', key: 'customer-id'));
      setUpMockOrders([o4], Filter.value('4', key: 'customer-id'));
    });
    test('peek', () async {
      Join<Customer, Order>? join;
      join = await relationship.peek('101');
      expect(join?.left.id, '1');
      expect(join?.right.id, '101');

      join = await relationship.peek('102');
      expect(join?.left.id, '2');
      expect(join?.right.id, '102');

      join = await relationship.peek('103');
      expect(join?.left.id, '1');
      expect(join?.right.id, '103');

      join = await relationship.peek('104');
      expect(join?.left.id, null);
      expect(join?.right.id, null);
    });
    test('pull', () async {
      Join<Customer, Order>? join;
      join = await relationship.pull('101').first;
      expect(join?.left.id, '1');
      expect(join?.right.id, '101');

      join = await relationship.pull('102').first;
      expect(join?.left.id, '2');
      expect(join?.right.id, '102');

      join = await relationship.pull('103').first;
      expect(join?.left.id, '1');
      expect(join?.right.id, '103');

      join = await relationship.pull('104').first;
      expect(join?.left.id, null);
      expect(join?.right.id, null);
    });
    test('peekAll', () async {
      final List<Join<Customer, List<Order>>> joins =
          await relationship.peekAll();
      expect(joins.length, 2);
      Join<Customer, List<Order>> join;

      join = joins[0];
      expect(join, isNotNull);
      expect(join.left.id, '1');
      expect(join.right.length, 2);
      expect(join.right[0].id, '101');
      expect(join.right[0].customerId, '1');
      expect(join.right[1].id, '103');
      expect(join.right[1].customerId, '1');

      join = joins[1];
      expect(join, isNotNull);
      expect(join.left.id, '2');
      expect(join.right.length, 1);
      expect(join.right[0].id, '102');
      expect(join.right[0].customerId, '2');
    });
    test('pullAll', () async {
      final List<Join<Customer, List<Order>>> joins =
          await relationship.pullAll().first;
      expect(joins.length, 2);
      Join<Customer, List<Order>> join;

      join = joins[0];
      expect(join.left.id, '1');
      expect(join.right.length, 2);
      expect(join.right[0].id, '101');
      expect(join.right[0].customerId, '1');
      expect(join.right[1].id, '103');
      expect(join.right[1].customerId, '1');

      join = joins[1];
      expect(join.left.id, '2');
      expect(join.right.length, 1);
      expect(join.right[0].id, '102');
      expect(join.right[0].customerId, '2');
    });
  });
  group('many-to-many', () {
    late ManyToManyRelationship<Item, Order, Product> relationship;
    late MockOrder o1;
    late MockOrder o2;
    late MockOrder o3;
    late MockOrder o4;

    late MockItem i1;
    late MockItem i2;
    late MockItem i3;
    late MockItem i4;
    setUp(() {
      relationship = ManyToManyRelationship(
        middle: itemsMock,
        left: ordersMock,
        right: productsMock,
        onLeft: (item) => item.orderId,
        onRight: (item) => item.productId,
      );

      o1 = MockOrder();
      setUpMockOrder(o1, '101', '1');
      mock.when(o1.date).thenReturn(DateTime(2023, 5, 10));
      mock.when(o1.amount).thenReturn(250);

      o2 = MockOrder();
      setUpMockOrder(o2, '102', '2');
      mock.when(o2.date).thenReturn(DateTime(2023, 6, 2));
      mock.when(o2.amount).thenReturn(150);

      o3 = MockOrder();
      setUpMockOrder(o3, '103', '1');
      mock.when(o3.date).thenReturn(DateTime(2023, 6, 20));
      mock.when(o3.amount).thenReturn(75);

      o4 = MockOrder();
      setUpMockOrder(o4, '104', '4');
      mock.when(o4.date).thenReturn(DateTime(2023, 6, 21));
      mock.when(o4.amount).thenReturn(200);

      setUpMockOrders([o1, o2, o3, o4], const Filter.empty());
      setUpMockOrders([o1, o3], Filter.value('1', key: 'customer-id'));
      setUpMockOrders([o2], Filter.value('2', key: 'customer-id'));
      setUpMockOrders([], Filter.value('3', key: 'customer-id'));
      setUpMockOrders([o4], Filter.value('4', key: 'customer-id'));

      i1 = MockItem();
      setUpMockItem(i1, '1', '101', '1');
      mock.when(i1.quantity).thenReturn(2);

      i2 = MockItem();
      setUpMockItem(i2, '2', '102', '3');
      mock.when(i2.quantity).thenReturn(1);

      i3 = MockItem();
      setUpMockItem(i3, '3', '102', '4');
      mock.when(i3.quantity).thenReturn(4);

      i4 = MockItem();
      setUpMockItem(i4, '4', '105', '2');
      mock.when(i4.quantity).thenReturn(3);

      setUpMockItems([]);
      setUpMockItems([i1, i2, i3, i4], const Filter.empty());
    });
    test('peek', () async {
      Join<Item, (Order?, Product?)>? join;
      join = await relationship.peek('1');
      expect(join?.left.id, '1');
      expect(join?.right.$1?.id, '101');
      expect(join?.right.$2?.id, '1');

      join = await relationship.peek('2');
      expect(join?.left.id, '2');
      expect(join?.right.$1?.id, '102');
      expect(join?.right.$2?.id, '3');

      join = await relationship.peek('3');
      expect(join?.left.id, '3');
      expect(join?.right.$1?.id, '102');
      expect(join?.right.$2?.id, null);

      join = await relationship.peek('4');
      expect(join?.left.id, '4');
      expect(join?.right.$1?.id, null);
      expect(join?.right.$2?.id, '2');
    });
    test('pull', () async {
      Join<Item, (Order?, Product?)>? join;
      join = await relationship.pull('1').first;
      expect(join?.left.id, '1');
      expect(join?.right.$1?.id, '101');
      expect(join?.right.$2?.id, '1');

      join = await relationship.pull('2').first;
      expect(join?.left.id, '2');
      expect(join?.right.$1?.id, '102');
      expect(join?.right.$2?.id, '3');

      join = await relationship.pull('3').first;
      expect(join?.left.id, '3');
      expect(join?.right.$1?.id, '102');
      expect(join?.right.$2?.id, null);

      join = await relationship.pull('4').first;
      expect(join?.left.id, '4');
      expect(join?.right.$1?.id, null);
      expect(join?.right.$2?.id, '2');
    }, skip: 'Not implemented');
  });
}
