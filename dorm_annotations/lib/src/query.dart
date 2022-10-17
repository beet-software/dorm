import 'package:meta/meta_meta.dart';

import 'field.dart';

enum QueryType { text }

@Target({TargetKind.getter})
class QueryField extends Field {
  final List<QueryToken> referTo;
  final String joinBy;

  const QueryField({
    required super.name,
    required this.referTo,
    this.joinBy = '_',
  });
}

class QueryToken {
  final Symbol field;
  final QueryType? type;

  const QueryToken(this.field, [this.type]);
}
