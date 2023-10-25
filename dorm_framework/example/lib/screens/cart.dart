import 'package:dorm_firebase_database/dorm_firebase_database.dart';
import 'package:dorm_framework/dorm_framework.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import 'order.dart';

class CartScreen extends StatelessWidget {
  final String cartId;

  const CartScreen({super.key, required this.cartId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<AsyncSnapshot<List<Join<CartItem, Product?>>>>(
          initialData: const AsyncSnapshot.waiting(),
          create: (_) => GetIt.instance
              .get<Dorm>()
              .cartItems
              .relationships
              .oneToOne(
                GetIt.instance.get<Dorm>().products.repository,
                on: (item) => item.productId,
              )
              .pullAll(Filter.value(cartId, key: 'cart-id'))
              .map((event) =>
                  AsyncSnapshot.withData(ConnectionState.active, event)),
        ),
      ],
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Cart')),
          body: Consumer<AsyncSnapshot<List<Join<CartItem, Product?>>>>(
            child: const Center(child: CircularProgressIndicator()),
            builder: (context, snapshot, child) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return child!;
              }
              final List<Join<CartItem, Product?>> joins = snapshot.data!;
              if (joins.isEmpty) {
                return const Center(child: Text('No items.'));
              }
              return ListView.builder(
                itemCount: joins.length,
                itemBuilder: (context, i) {
                  final CartItem order = joins[i].left;
                  // If `product` is removed during this query
                  final Product? product = joins[i].right;
                  return ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(product?.name ?? '<deleted>'),
                    trailing: Text('x${order.amount}'),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () async {
              final OrderResult? result = await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const OrderScreen()));
              if (result == null) return;

              await GetIt.instance.get<Dorm>().cartItems.repository.put(
                    CartItemDependency(
                        productId: result.productId, cartId: cartId),
                    CartItemData(amount: result.amount),
                  );
            },
          ),
        ),
      ),
    );
  }
}
