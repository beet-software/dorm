enum QueryType { text, value, date }

class Field {
  final String? name;
  final QueryType? queryBy;

  const Field({
    required this.name,
    this.queryBy,
  });
}

class ForeignField extends Field {
  final Type referTo;

  const ForeignField({
    required super.name,
    super.queryBy,
    required this.referTo,
  });
}

