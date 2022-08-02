import 'uid_type.dart';

/// Represents an abstract model to be mapped.
class Model {
  final String name;
  final String? repositoryName;
  final UidType uidType;

  const Model({
    required this.name,
    this.repositoryName,
    this.uidType = const UidType.simple(),
  });
}
