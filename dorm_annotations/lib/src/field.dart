import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class Field {
  final String? name;
  final Object? defaultValue;

  const Field({
    this.name,
    this.defaultValue,
  });
}

@Target({TargetKind.getter})
class ForeignField extends Field {
  final Type referTo;

  const ForeignField({
    required super.name,
    required this.referTo,
  });
}

@Target({TargetKind.getter})
class ModelField extends Field {
  final Type referTo;

  const ModelField({
    required super.name,
    required this.referTo,
  });
}
