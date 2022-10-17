import 'package:meta/meta_meta.dart';

import 'field.dart';

@Target({TargetKind.classType})
class PolymorphicData {
  final String name;

  const PolymorphicData({required this.name});
}

@Target({TargetKind.getter})
class PolymorphicField extends Field {
  final String pivotName;

  const PolymorphicField({
    required super.name,
    required this.pivotName,
  });
}


