import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart' as ffb;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models.dart';

abstract class _FormGroup<T> extends ffb.GroupFieldBloc<ffb.FieldBloc, void> {
  _FormGroup({super.fieldBlocs});

  T get value;
}

class _ProductFormGroup extends _FormGroup<ProductReviewContent> {
  final ffb.InputFieldBloc<int, void> rating;

  _ProductFormGroup({required this.rating}) : super(fieldBlocs: [rating]);

  @override
  ProductReviewContent get value => ProductReviewContent(rating: rating.value);
}

class _UserFormGroup extends _FormGroup<UserReviewContent> {
  final ffb.InputFieldBloc<String, void> userId;

  _UserFormGroup({required this.userId}) : super(fieldBlocs: [userId]);

  @override
  UserReviewContent get value => UserReviewContent(userId: userId.value);
}

class _ServiceFormGroup extends _FormGroup<ServiceReviewContent> {
  final ffb.SelectFieldBloc<ReviewSatisfaction, void> rating;

  _ServiceFormGroup({required this.rating}) : super(fieldBlocs: [rating]);

  @override
  ServiceReviewContent get value => ServiceReviewContent(rating: rating.value!);
}

class ReviewForm extends ffb.FormBloc<ReviewData, void> {
  late final ffb.TextFieldBloc<void> text;
  late final ffb.SelectFieldBloc<ReviewContentType, void> type;

  late final _UserFormGroup _userRole;
  late final _ProductFormGroup _productRole;
  late final _ServiceFormGroup _serviceRole;

  final List<StreamSubscription<void>> _subscriptions = [];

  ReviewForm([ReviewData? data]) {
    text = ffb.TextFieldBloc(
      initialValue: data?.text ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    type = ffb.SelectFieldBloc(
      initialValue: data?.type,
      validators: [ffb.FieldBlocValidators.required],
      items: ReviewContentType.values,
    );
    _userRole = _UserFormGroup(
      userId: ffb.InputFieldBloc(
        initialValue: data?.type == ReviewContentType.user
            ? (data?.content as UserReviewContent).userId
            : '',
        validators: [ffb.FieldBlocValidators.required],
      ),
    );
    _productRole = _ProductFormGroup(
      rating: ffb.InputFieldBloc(
        initialValue: data?.type == ReviewContentType.product
            ? (data?.content as ProductReviewContent).rating
            : 5,
        validators: [ffb.FieldBlocValidators.required],
      ),
    );
    _serviceRole = _ServiceFormGroup(
      rating: ffb.SelectFieldBloc(
        initialValue: data?.type == ReviewContentType.service
            ? (data?.content as ServiceReviewContent).rating
            : null,
        validators: [ffb.FieldBlocValidators.required],
        items: ReviewSatisfaction.values,
      ),
    );

    addFieldBlocs(fieldBlocs: [
      text,
      type,
      if (data != null) ..._access(data.type).flatFieldBlocs,
    ]);
    _subscriptions.add(type.onValueChanges(onData: (_, state) async* {
      removeFieldBlocs(
        fieldBlocs: ReviewContentType.values
            .map(_access)
            .expand((bloc) => bloc.flatFieldBlocs)
            .toList(),
      );
      final ReviewContentType? type = state.value;
      if (type == null) return;
      addFieldBlocs(fieldBlocs: _access(type).flatFieldBlocs.toList());
    }));
  }

  _FormGroup<ReviewContent> _access(ReviewContentType type) {
    switch (type) {
      case ReviewContentType.user:
        return _userRole;
      case ReviewContentType.service:
        return _serviceRole;
      case ReviewContentType.product:
        return _productRole;
    }
  }

  @override
  void onSubmitting() {
    final ReviewContentType type = this.type.value!;
    emitSuccess(
      successResponse: ReviewData(
        timestamp: DateTime.now(),
        text: text.value,
        type: type,
        content: _access(type).value,
      ),
    );
  }

  @override
  Future<void> close() async {
    await Future.wait(
        _subscriptions.map((subscription) => subscription.cancel()));
    return super.close();
  }
}

class ReviewFormScreen extends StatelessWidget {
  final ReviewForm form;

  const ReviewFormScreen({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('New review')),
        body: ffb.FormBlocListener<ReviewForm, ReviewData, void>(
          formBloc: form,
          onSuccess: (context, state) {
            Navigator.of(context).pop(state.successResponse);
          },
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              ffb.TextFieldBlocBuilder(
                textFieldBloc: form.text,
                maxLength: 300,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Describe your review',
                  border: OutlineInputBorder(),
                ),
              ),
              ffb.DropdownFieldBlocBuilder<ReviewContentType>(
                selectFieldBloc: form.type,
                itemBuilder: (context, type) => ffb.FieldItem(
                  child: Text(switch (type) {
                    ReviewContentType.product => 'Product',
                    ReviewContentType.user => 'User',
                    ReviewContentType.service => 'Service',
                  }),
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Review type',
                ),
              ),
              // ffb.TextFieldBlocBuilder(
              //   textFieldBloc: form._userRole.userId,
              //   decoration: const InputDecoration(
              //     prefixIcon: Icon(Icons.pin_drop),
              //     labelText: 'Distrito da escola',
              //   ),
              // ),
              ffb.CanShowFieldBlocBuilder(
                fieldBloc: form._productRole.rating,
                builder: (context, _) => ffb.BlocBuilder<
                    ffb.InputFieldBloc<int, void>,
                    ffb.InputFieldBlocState<int, void>>(
                  bloc: form._productRole.rating,
                  builder: (context, state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Text('How do you rate it?'),
                      ),
                      Center(
                        child: RatingBar.builder(
                          initialRating: state.value.toDouble(),
                          minRating: 1,
                          direction: Axis.horizontal,
                          itemCount: 5,
                          itemPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          itemBuilder: (context, _) {
                            return const Icon(Icons.star, color: Colors.amber);
                          },
                          onRatingUpdate: (rating) {
                            form._productRole.rating
                                .updateValue(rating.toInt());
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              ffb.RadioButtonGroupFieldBlocBuilder<ReviewSatisfaction>(
                selectFieldBloc: form._serviceRole.rating,
                canTapItemTile: true,
                itemBuilder: (context, item) => ffb.FieldItem(
                  child: Text(switch (item) {
                    ReviewSatisfaction.good => 'Excellent',
                    ReviewSatisfaction.ok => 'Regular',
                    ReviewSatisfaction.bad => 'Horrible',
                  }),
                ),
                decoration: const InputDecoration(
                  labelText: 'How did you feel?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),
              MaterialButton(
                color: Theme.of(context).primaryColor,
                onPressed: form.submit,
                child: const Text(
                  'submit',
                  style: TextStyle(color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
