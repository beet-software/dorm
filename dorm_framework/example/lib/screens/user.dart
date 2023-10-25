import 'dart:async';

import 'package:dorm_firebase_database/dorm_firebase_database.dart';
import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import 'cart.dart';
import 'review_form.dart';
import 'user_form.dart';

class _Query extends ValueNotifier<AsyncSnapshot<List<Review>>> {
  final String userId;
  StreamSubscription<void>? _subscription;

  _Query({required this.userId}) : super(const AsyncSnapshot.waiting()) {
    _subscription = GetIt.instance
        .get<Dorm>()
        .reviews
        .repository
        .pullAll(Filter.value(userId, key: 'user-id'))
        .map((users) => AsyncSnapshot.withData(ConnectionState.active, users))
        .listen((snapshot) => value = snapshot);
  }

  ReviewContentType? _type;

  ReviewContentType? get type => _type;

  void updateFilter(ReviewContentType? type) {
    _type = type;
    final String query =
        [userId, if (type != null) $normalizeEnum(type)].join('_');

    value = const AsyncSnapshot.waiting();
    _subscription = GetIt.instance
        .get<Dorm>()
        .reviews
        .repository
        .pullAll(Filter.text(query, key: '_q-type'))
        .map((users) => AsyncSnapshot.withData(ConnectionState.active, users))
        .listen((snapshot) => value = snapshot);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

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
        ChangeNotifierProvider<_Query>(create: (_) => _Query(userId: userId)),
      ],
      child: SafeArea(
        child: Consumer<AsyncSnapshot<Cart?>>(
          builder: (context, cartSnapshot, _) {
            final Cart? cart = cartSnapshot.data;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Profile'),
                actions: [
                  IconButton(
                    onPressed: () async {
                      final ReviewData? data = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReviewFormScreen(form: ReviewForm()),
                        ),
                      );
                      if (data == null) return;
                      await GetIt.instance
                          .get<Dorm>()
                          .reviews
                          .repository
                          .put(ReviewDependency(userId: userId), data);
                    },
                    icon: const Icon(Icons.reviews),
                  ),
                ],
              ),
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
                      _CartCard(userId: userId, cart: cart),
                      const ListTile(title: Text('My reviews')),
                      Expanded(
                        child: Consumer<_Query>(
                          child:
                              const Center(child: CircularProgressIndicator()),
                          builder: (context, query, child) {
                            final AsyncSnapshot<List<Review>> snapshot =
                                query.value;
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return child!;
                            }
                            final List<Review> reviews = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (query.type != null || reviews.isNotEmpty)
                                  _FilterCard(query: query),
                                Expanded(
                                  child: reviews.isEmpty
                                      ? const Center(
                                          child: Text('No reviews yet.'),
                                        )
                                      : ListView.builder(
                                          itemCount: reviews.length,
                                          itemBuilder: (context, i) {
                                            final Review review = reviews[i];
                                            return ListTile(
                                              leading:
                                                  const Icon(Icons.rate_review),
                                              title: Text(review.text),
                                              subtitle: Text(DateFormat(
                                                      'dd/MM/yyyy')
                                                  .format(review.timestamp)),
                                              trailing: IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () async {
                                                  await GetIt.instance
                                                      .get<Dorm>()
                                                      .reviews
                                                      .repository
                                                      .pop(review.id);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final _Query query;

  const _FilterCard({required this.query});

  @override
  Widget build(BuildContext context) {
    final ReviewContentType? selectedType = query.type;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (ReviewContentType type in ReviewContentType.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FilterChip(
                selected: selectedType == type,
                label: Text(switch (type) {
                  ReviewContentType.product => 'products',
                  ReviewContentType.user => 'users',
                  ReviewContentType.service => 'services',
                }),
                onSelected: (value) => query.updateFilter(value ? type : null),
              ),
            ),
        ],
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

class _CartCard extends StatelessWidget {
  final String userId;
  final Cart? cart;

  const _CartCard({required this.cart, required this.userId});

  @override
  Widget build(BuildContext context) {
    final Cart? cart = this.cart;
    if (cart == null) {
      return ListTile(
        leading: const Icon(Icons.shopping_cart),
        title: const Text('Cart'),
        subtitle: const Text('Your cart is empty.'),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle),
          onPressed: () async {
            await GetIt.instance.get<Dorm>().carts.repository.put(
                  CartDependency(userId: userId),
                  CartData(timestamp: DateTime.now()),
                );
          },
        ),
      );
    }
    return ListTile(
      leading: const Icon(Icons.shopping_cart),
      title: const Text('Cart'),
      subtitle: const Text('Click here to access your cart'),
      onTap: () async {
        await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CartScreen(cartId: cart.id)));
      },
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
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

          await GetIt.instance.get<Dorm>().carts.repository.pop(cart.id);
        },
      ),
    );
  }
}
