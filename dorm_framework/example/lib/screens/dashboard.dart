import 'package:dorm_framework/dorm_framework.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../models.dart';

typedef _OrderView = List<Join<User, Product?>>;
typedef _CountView = List<Join<Product, CartItem>>;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Allows reading all products ordered by an user through
        // User -> Cart -> CartItem -> Product.
        StreamProvider<AsyncSnapshot<_OrderView>>(
          initialData: const AsyncSnapshot.waiting(),
          create: (_) => GetIt.instance
              .get<Dorm>()
              .relations
              .users
              .carts
              .items
              .productOrNull
              .pullAll()
              .map((event) =>
                  AsyncSnapshot.withData(ConnectionState.active, event)),
        ),
        // Allows reading how many times a product was included in a order
        StreamProvider<AsyncSnapshot<_CountView>>(
          initialData: const AsyncSnapshot.waiting(),
          create: (_) => GetIt.instance
              .get<Dorm>()
              .relations
              .products
              .cartItems
              .pullAll()
              .map((event) =>
                  AsyncSnapshot.withData(ConnectionState.active, event)),
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
                    final Map<User, Set<String>> grouped = {};
                    for (final Join<User, Product?> join in joins) {
                      final Product? product = join.right;
                      if (product == null) continue;
                      grouped.putIfAbsent(join.left, () => {}).add(product.name);
                    }
                    final List<MapEntry<User, Set<String>>> entries =
                        grouped.entries.toList();
                    return ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final User user = entries[i].key;
                        final Set<String> products = entries[i].value;

                        return ListTile(
                          leading: const Icon(Icons.person_search),
                          title: Text('@${user.username}'),
                          subtitle: Text(
                            products.join(', '),
                          ),
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
                    final Map<Product, List<CartItem>> grouped = {};
                    for (final Join<Product, CartItem> join in joins) {
                      grouped.putIfAbsent(join.left, () => []).add(join.right);
                    }
                    final List<MapEntry<Product, List<CartItem>>> entries =
                        grouped.entries.toList();
                    return ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final Product product = entries[i].key;
                        final List<CartItem> items = entries[i].value;
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
