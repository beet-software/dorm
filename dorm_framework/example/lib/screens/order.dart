import 'package:decimal/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart' as ffb;
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../models.dart';
import 'product_form.dart';

class OrderResult {
  final String productId;
  final int amount;

  const OrderResult({required this.productId, required this.amount});
}

class OrderForm extends ffb.FormBloc<OrderResult, void> {
  final ffb.InputFieldBloc<String?, void> productId = ffb.InputFieldBloc(
    initialValue: null,
    validators: [ffb.FieldBlocValidators.required],
  );
  final ffb.InputFieldBloc<int, void> amount = ffb.InputFieldBloc(
    initialValue: 1,
    validators: [
      (value) => value >= 1 ? null : ffb.FieldBlocValidatorsErrors.required,
    ],
  );
  final ffb.BooleanFieldBloc<void> editing = ffb.BooleanFieldBloc();

  OrderForm() {
    addFieldBlocs(fieldBlocs: [productId, amount, editing]);
  }

  @override
  void onSubmitting() {
    emitSuccess(
      successResponse: OrderResult(
        productId: productId.value!,
        amount: amount.value,
      ),
    );
  }
}

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<AsyncSnapshot<List<Product>>>(
          initialData: const AsyncSnapshot.waiting(),
          create: (_) => GetIt.instance
              .get<Dorm>()
              .products
              .repository
              .pullAll()
              .map((event) =>
                  AsyncSnapshot.withData(ConnectionState.active, event)),
        ),
        ffb.BlocProvider<OrderForm>(create: (_) => OrderForm()),
      ],
      child: SafeArea(
        child: Consumer<OrderForm>(
          builder: (context, form, _) {
            return ffb.FormBlocListener<OrderForm, OrderResult, void>(
              onSuccess: (context, state) =>
                  Navigator.of(context).pop(state.successResponse),
              child: ffb.BlocSelector<ffb.BooleanFieldBloc<void>,
                  ffb.BooleanFieldBlocState<void>, bool>(
                bloc: form.editing,
                selector: (state) => state.value,
                builder: (context, editing) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Amount'),
                      actions: [
                        editing
                            ? IconButton(
                                icon: const Icon(Icons.list),
                                onPressed: () =>
                                    form.editing.updateValue(false),
                              )
                            : IconButton(
                                icon: const Icon(Icons.dashboard_customize),
                                onPressed: () => form.editing.updateValue(true),
                              ),
                      ],
                    ),
                    body: ffb.BlocSelector<ffb.InputFieldBloc<String?, void>,
                        ffb.InputFieldBlocState<String?, void>, String?>(
                      bloc: form.productId,
                      selector: (state) => state.value,
                      builder: (context, selectedProductId) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _ProductList(
                                editing: editing,
                                isSelected: (product) => editing
                                    ? false
                                    : product.id == selectedProductId,
                                onSelected: editing
                                    ? null
                                    : (product) => form.productId.updateValue(
                                        product.id == selectedProductId
                                            ? null
                                            : product.id),
                              ),
                            ),
                            if (!editing && selectedProductId != null)
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: ffb.BlocSelector<
                                    ffb.InputFieldBloc<int, void>,
                                    ffb.InputFieldBlocState<int, void>,
                                    int>(
                                  bloc: form.amount,
                                  selector: (state) => state.value,
                                  builder: (context, value) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SpinBox(
                                          value: value.toDouble(),
                                          onChanged: (value) => form.amount
                                              .updateValue(value.toInt()),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            labelText: 'Amount',
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        MaterialButton(
                                          onPressed: form.submit,
                                          child: const Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Text('submit'),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    floatingActionButton: editing
                        ? FloatingActionButton(
                            onPressed: () async {
                              final ProductData? data =
                                  await Navigator.of(context)
                                      .push(MaterialPageRoute(
                                builder: (_) =>
                                    ProductFormScreen(form: ProductForm()),
                              ));
                              if (data == null) return;
                              await GetIt.instance
                                  .get<Dorm>()
                                  .products
                                  .repository
                                  .put(const ProductDependency(), data);
                            },
                            child: const Icon(Icons.add),
                          )
                        : null,
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

class _ProductList extends StatelessWidget {
  final bool editing;
  final bool Function(Product) isSelected;
  final void Function(Product)? onSelected;

  const _ProductList({
    required this.onSelected,
    required this.isSelected,
    required this.editing,
  });

  @override
  Widget build(BuildContext context) {
    final void Function(Product)? onSelected = this.onSelected;
    return Consumer<AsyncSnapshot<List<Product>>>(
      child: const Center(child: CircularProgressIndicator()),
      builder: (context, snapshot, child) {
        if (snapshot.connectionState == ConnectionState.waiting) return child!;
        final List<Product> products = snapshot.data!;
        if (products.isEmpty) {
          return const Center(child: Text('No products.'));
        }
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, i) {
            final Product product = products[i];
            return ListTile(
              leading: Icon(
                Icons.shopping_bag,
                color:
                    isSelected(product) ? Theme.of(context).primaryColor : null,
              ),
              title: Text(product.name),
              onTap: (editing || onSelected == null)
                  ? null
                  : () => onSelected(product),
              subtitle: editing ? null : Text(product.description),
              trailing: editing
                  ? PopupMenuButton<bool>(
                      onSelected: (action) async {
                        if (action) {
                          final ProductData? data =
                              await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) {
                              return ProductFormScreen(
                                form: ProductForm(product),
                              );
                            }),
                          );
                          if (data == null) return;
                          await GetIt.instance
                              .get<Dorm>()
                              .products
                              .repository
                              .push(GetIt.instance
                                  .get<Dorm>()
                                  .products
                                  .convert(product, data));
                        } else {
                          final bool? confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Confirm action'),
                              content: const Text(
                                'Are you sure you want to delete this product? '
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
                              .products
                              .repository
                              .pop(product.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: true,
                          child: Text('edit'),
                        ),
                        const PopupMenuItem(
                          value: false,
                          child: Text(
                            'remove',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    )
                  : Text(intl.NumberFormat.currency(locale: 'en_US')
                      .format(DecimalIntl(product.price))),
            );
          },
        );
      },
    );
  }
}
