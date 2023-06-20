import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import 'cart.dart';
import 'user_form.dart';

class UserScreen extends StatelessWidget {
  final String userId;

  const UserScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<AsyncSnapshot<User?>>(
          initialData: const AsyncSnapshot.waiting(),
          create: (_) => GetIt.instance
              .get<Dorm>()
              .users
              .repository
              .pull(userId)
              .map((event) =>
                  AsyncSnapshot.withData(ConnectionState.active, event)),
        ),
        StreamProvider<AsyncSnapshot<Cart?>>(
          initialData: const AsyncSnapshot.waiting(),
          create: (_) => GetIt.instance
              .get<Dorm>()
              .carts
              .repository
              .pull(userId)
              .map((event) =>
                  AsyncSnapshot.withData(ConnectionState.active, event)),
        ),
      ],
      child: SafeArea(
        child: Consumer<AsyncSnapshot<Cart?>>(
          builder: (context, cartSnapshot, _) {
            final Cart? cart = cartSnapshot.data;
            return Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              body: Consumer<AsyncSnapshot<User?>>(
                child: const Center(child: CircularProgressIndicator()),
                builder: (context, userSnapshot, child) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return child!;
                  }
                  final User? user = userSnapshot.data;
                  if (user == null) {
                    return const Center(child: Text('This user was deleted.'));
                  }
                  if (cartSnapshot.connectionState == ConnectionState.waiting) {
                    return child!;
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5),
                        child: _UserCard(user: user),
                      ),
                      Expanded(
                        child: Center(
                          child: cart == null
                              ? const Text('No cart is created yet.')
                              : MaterialButton(
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                CartScreen(cartId: cart.id)));
                                  },
                                  color: Theme.of(context).primaryColor,
                                  child: const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Text(
                                      'go to cart',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                        ),
                      )
                    ],
                  );
                },
              ),
              floatingActionButton:
                  cartSnapshot.connectionState == ConnectionState.waiting
                      ? null
                      : cart == null
                          ? FloatingActionButton(
                              child: const Icon(Icons.add_shopping_cart),
                              onPressed: () async {
                                await GetIt.instance
                                    .get<Dorm>()
                                    .carts
                                    .repository
                                    .put(
                                      CartDependency(userId: userId),
                                      CartData(timestamp: DateTime.now()),
                                    );
                              },
                            )
                          : FloatingActionButton(
                              child: const Icon(Icons.remove_shopping_cart),
                              onPressed: () async {
                                final bool? confirm = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirm action'),
                                    content: const Text(
                                      'Are you sure you want to empty your cart? '
                                      'This action can NOT be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text(
                                          'cancel',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('proceed'),
                                      ),
                                    ],
                                  ),
                                );
                                if (!(confirm ?? false)) return;
                                await GetIt.instance
                                    .get<Dorm>()
                                    .carts
                                    .repository
                                    .pop(cart.id);
                              },
                            ),
            );
          },
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user.profile.name),
              subtitle: Text('@${user.username}'),
            ),
            ListTile(
              trailing: const Text('email'),
              title: Text(user.email),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  OutlinedButton(
                    child: const Text('edit'),
                    onPressed: () async {
                      final UserData? data =
                          await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => UserFormScreen(form: UserForm(user)),
                      ));
                      if (data == null) return;
                      await GetIt.instance.get<Dorm>().users.repository.push(
                          GetIt.instance.get<Dorm>().users.convert(user, data));
                    },
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () async {
                      final bool? confirm = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirm action'),
                          content: const Text(
                            'Are you sure you want to delete this user? '
                            'This action can NOT be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'cancel',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('proceed'),
                            ),
                          ],
                        ),
                      );
                      if (!(confirm ?? false)) return;

                      await GetIt.instance
                          .get<Dorm>()
                          .users
                          .repository
                          .pop(user.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text(
                      'delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
