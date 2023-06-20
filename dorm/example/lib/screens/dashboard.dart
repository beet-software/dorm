import 'package:dorm/dorm.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../models.dart';

typedef _OrderView = List<Join<User, List<Join<CartItem, Product?>>>>;
typedef _CountView = List<Join<Product, List<CartItem>>>;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Allows reading all products ordered by an user
        StreamProvider<AsyncSnapshot<_OrderView>>(
          initialData: const AsyncSnapshot.waiting(),
          create: (_) => OneToManyRelationship(
            left: GetIt.instance.get<Dorm>().users.repository,
            right: OneToOneRelationship(
              left: GetIt.instance.get<Dorm>().cartItems.repository,
              right: GetIt.instance.get<Dorm>().products.repository,
              on: (item) => item.productId,
            ),
            on: (user) => Filter.value(user.id, key: 'cart-id'),
          ).pullAll().map(
              (event) => AsyncSnapshot.withData(ConnectionState.active, event)),
        ),
        // Allows reading how many times a product was included in a order
        StreamProvider<AsyncSnapshot<_CountView>>(
          initialData: const AsyncSnapshot.waiting(),
          create: (_) => ManyToOneRelationship(
            left: GetIt.instance.get<Dorm>().cartItems.repository,
            right: GetIt.instance.get<Dorm>().products.repository,
            on: (item) => item.productId,
          ).pullAll().map(
              (event) => AsyncSnapshot.withData(ConnectionState.active, event)),
        ),
      ],
      child: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              bottom: const TabBar(
                tabs: [Tab(text: 'By users'), Tab(text: 'By products')],
              ),
            ),
            body: TabBarView(
              children: [
                Consumer<AsyncSnapshot<_OrderView>>(
                  child: const Center(child: CircularProgressIndicator()),
                  builder: (context, snapshot, child) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return child!;
                    }
                    final _OrderView joins = snapshot.data!;
                    return ListView.builder(
                      itemCount: joins.length,
                      itemBuilder: (context, i) {
                        final User user = joins[i].left;
                        final Map<Product, int> amounts = {};
                        for (Join<CartItem, Product?> join in joins[i].right) {
                          final CartItem item = join.left;
                          final Product? product = join.right;
                          if (product == null) continue;
                          final int amount = item.amount;
                          amounts[product] = (amounts[product] ?? 0) + amount;
                        }
                        final List<MapEntry<Product, int>> entries =
                            amounts.entries.toList()
                              ..sort((e1, e0) => e0.value.compareTo(e1.value));

                        return ListTile(
                          leading: const Icon(Icons.person_search),
                          title: Text('@${user.username}'),
                          subtitle: Text(entries
                              .map((entry) =>
                                  '${entry.key.name} (x${entry.value})')
                              .join(', ')),
                        );
                      },
                    );
                  },
                ),
                Consumer<AsyncSnapshot<_CountView>>(
                  child: const Center(child: CircularProgressIndicator()),
                  builder: (context, snapshot, child) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return child!;
                    }
                    final _CountView joins = snapshot.data!;
                    return ListView.builder(
                      itemCount: joins.length,
                      itemBuilder: (context, i) {
                        final Product product = joins[i].left;
                        final List<CartItem> items = joins[i].right;
                        final int count =
                            items.map((item) => item.cartId).toSet().length;
                        return ListTile(
                          leading: const Icon(Icons.shopping_bag),
                          title: Text(product.name),
                          subtitle: Text(
                            'ordered by $count user${count == 1 ? '' : 's'}',
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
