import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_bloc/flutter_form_bloc.dart' as ffb;

import '../models.dart';

class UserForm extends ffb.FormBloc<UserData, void> {
  final UserData? _data;
  late final ffb.TextFieldBloc<void> username;
  late final ffb.TextFieldBloc<void> email;
  late final ffb.TextFieldBloc<void> profileName;
  late final ffb.TextFieldBloc<void> profileBirthDate;
  late final ffb.TextFieldBloc<void> profileBio;

  bool get hasInitialValue => _data != null;

  UserForm([UserData? data]) : _data = data {
    username = ffb.TextFieldBloc(
      initialValue: data?.username ?? '',
      validators: [ffb.FieldBlocValidators.required],
    );
    email = ffb.TextFieldBloc(
      initialValue: data?.email ?? '',
      validators: [
        ffb.FieldBlocValidators.required,
        ffb.FieldBlocValidators.email,
      ],
    );
    profileName = ffb.TextFieldBloc(
      initialValue: data?.profile.name ?? '',
      validators: [
        ffb.FieldBlocValidators.required,
      ],
    );
    profileBirthDate = ffb.TextFieldBloc(
      initialValue: data == null
          ? ''
          : ffb.DateFormat('yyyy-MM-dd').format(data.profile.birthDate),
      validators: [
        ffb.FieldBlocValidators.required,
        (text) {
          try {
            ffb.DateFormat('yyyy-MM-dd').parse(text);
            return null;
          } on FormatException {
            return 'This field is invalid.';
          }
        },
      ],
    );
    profileBio = ffb.TextFieldBloc(
      initialValue: data?.profile.bio ?? '',
    );
    addFieldBlocs(fieldBlocs: [
      username,
      email,
      profileName,
      profileBirthDate,
      profileBio,
    ]);
  }

  UserData? get response {
    final String bio = profileBio.value;
    return UserData(
      username: username.value,
      email: email.value,
      profile: Profile(
        name: profileName.value,
        birthDate: ffb.DateFormat('yyyy-MM-dd').parse(profileBirthDate.value),
        bio: bio.trimLeft().isEmpty ? null : bio.trim(),
      ),
    );
  }

  @override
  void onSubmitting() {
    emitSuccess(successResponse: response);
  }
}

class UserFormScreen extends StatelessWidget {
  final UserForm form;

  const UserFormScreen({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('${form.hasInitialValue ? 'Edit' : 'Creat'}ing user'),
        ),
        body: ffb.FormBlocListener<UserForm, UserData, void>(
          formBloc: form,
          onSuccess: (context, state) {
            Navigator.of(context).pop(state.successResponse);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              ffb.TextFieldBlocBuilder(
                textFieldBloc: form.username,
                maxLength: 15,
                autofillHints: const [AutofillHints.username],
                inputFormatters: [FilteringTextInputFormatter.deny(' ')],
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixText: '@ ',
                ),
              ),
              ffb.TextFieldBlocBuilder(
                textFieldBloc: form.email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                inputFormatters: [FilteringTextInputFormatter.deny(' ')],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const ListTile(title: Text('Profile')),
              ffb.TextFieldBlocBuilder(
                textFieldBloc: form.profileName,
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
              ),
              ffb.TextFieldBlocBuilder(
                textFieldBloc: form.profileBirthDate,
                keyboardType: TextInputType.datetime,
                autofillHints: const [AutofillHints.birthday],
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Birth date',
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              ffb.TextFieldBlocBuilder(
                textFieldBloc: form.profileBio,
                minLines: 1,
                maxLines: 5,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Bio (optional)',
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
