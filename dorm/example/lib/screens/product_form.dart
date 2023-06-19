import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart' as ffb;

import '../models.dart';

class ProductForm extends ffb.FormBloc<ProductData, void> {
  final ProductData? _data;
  late final ffb.TextFieldBloc<void> name;
  late final ffb.TextFieldBloc<void> description;
  late final ffb.TextFieldBloc<void> price;

  bool get hasInitialValue => _data != null;

  ProductForm([ProductData? data]) : _data = data {
    name = ffb.TextFieldBloc(
      validators: [ffb.FieldBlocValidators.required],
    );
    description = ffb.TextFieldBloc(
      validators: [ffb.FieldBlocValidators.required],
    );
    price = ffb.TextFieldBloc(
      validators: [
        ffb.FieldBlocValidators.required,
        (text) =>
            Decimal.tryParse(text) == null ? 'This field is invalid.' : null,
      ],
    );

    addFieldBlocs(fieldBlocs: [name, description, price]);
  }

  @override
  void onSubmitting() {
    emitSuccess(
      successResponse: ProductData(
        name: name.value,
        description: description.value,
        price: Decimal.parse(price.value),
      ),
    );
  }
}

class ProductFormScreen extends StatelessWidget {
  final ProductForm form;

  const ProductFormScreen({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('${form.hasInitialValue ? 'Edit' : 'Creat'}ing product'),
        ),
        body: ffb.FormBlocListener<ProductForm, ProductData, void>(
          formBloc: form,
          onSuccess: (context, state) {
            Navigator.of(context).pop(state.successResponse);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              ffb.TextFieldBlocBuilder(
                textFieldBloc: form.name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              ffb.TextFieldBlocBuilder(
                textFieldBloc: form.description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              ffb.TextFieldBlocBuilder(
                textFieldBloc: form.price,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
              ),
              MaterialButton(
                onPressed: form.submit,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
