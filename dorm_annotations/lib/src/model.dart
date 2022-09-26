import 'package:meta/meta_meta.dart';

import 'uid_type.dart';

/// Represents an abstract schema to be mapped.
@Target({TargetKind.classType})
class Model {
  final String name;
  final Symbol? as;
  final UidType uidType;

  const Model({
    required this.name,
    this.as,
    this.uidType = const UidType.simple(),
  });
}
