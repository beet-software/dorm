import 'package:meta/meta_meta.dart';

enum QueryType { text, value, date }

@Target({TargetKind.getter})
class Field {
  final String? name;
  final QueryType? queryBy;

  const Field({
    required this.name,
    this.queryBy,
  });
}

@Target({TargetKind.getter})
class ForeignField extends Field {
  final Type referTo;

  const ForeignField({
    required super.name,
    super.queryBy,
    required this.referTo,
  });
}
