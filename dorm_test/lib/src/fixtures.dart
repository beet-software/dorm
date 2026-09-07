import 'package:dorm_framework/dorm_framework.dart';

class ComplianceDependency<T> extends Dependency<T> {
  const ComplianceDependency() : super.strong();
}

class ComplianceItemData {
  final String name;
  final int value;
  final bool active;

  const ComplianceItemData({
    required this.name,
    required this.value,
    required this.active,
  });
}

class ComplianceItem extends ComplianceItemData {
  final String id;

  const ComplianceItem({
    required this.id,
    required super.name,
    required super.value,
    required super.active,
  });

  @override
  bool operator ==(Object other) =>
      other is ComplianceItem &&
      id == other.id &&
      name == other.name &&
      value == other.value &&
      active == other.active;

  @override
  int get hashCode => Object.hash(id, name, value, active);
}

class ComplianceItemEntity
    implements
        Entity<
          ComplianceItemData,
          ComplianceItem,
          String,
          SimpleCreation<ComplianceItemData, String>
        > {
  const ComplianceItemEntity();

  @override
  final EntitySchema schema = const EntitySchema(
    tableName: 'dorm_compliance_items',
    primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
    fields: [
      FieldSchema(fieldName: 'name', columnName: 'name'),
      FieldSchema(fieldName: 'value', columnName: 'value'),
      FieldSchema(fieldName: 'active', columnName: 'active'),
    ],
  );

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  bool get supportsAutomaticIdentity => true;

  @override
  ComplianceItem fromJson(String id, Map data) {
    return ComplianceItem(
      id: id,
      name: data['name'] as String,
      value: data['value'] as int,
      active: data['active'] as bool,
    );
  }

  @override
  Map<String, Object?> toJson(ComplianceItemData data) => {
    'name': data.name,
    'value': data.value,
    'active': data.active,
  };

  @override
  ComplianceItem convert(ComplianceItem model, ComplianceItemData data) {
    return ComplianceItem(
      id: model.id,
      name: data.name,
      value: data.value,
      active: data.active,
    );
  }

  @override
  ComplianceItem fromData(
    ResolvedCreation<ComplianceItemData, String> creation,
  ) {
    return ComplianceItem(
      id: creation.id,
      name: creation.data.name,
      value: creation.data.value,
      active: creation.data.active,
    );
  }

  @override
  String identify(ComplianceItem model) => model.id;
}

class ComplianceCompositeData {
  final String value;

  const ComplianceCompositeData(this.value);
}

class ComplianceComposite extends ComplianceCompositeData {
  final CompositeKey id;

  const ComplianceComposite({required this.id, required String value})
    : super(value);

  @override
  bool operator ==(Object other) =>
      other is ComplianceComposite && id == other.id && value == other.value;

  @override
  int get hashCode => Object.hash(id, value);
}

class ComplianceCompositeEntity
    implements
        Entity<
          ComplianceCompositeData,
          ComplianceComposite,
          CompositeKey,
          ExplicitCreation<ComplianceCompositeData, CompositeKey>
        > {
  const ComplianceCompositeEntity();

  @override
  final EntitySchema schema = const EntitySchema(
    tableName: 'dorm_compliance_composites',
    primaryKeys: [
      FieldSchema(fieldName: 'tenant', columnName: 'tenant'),
      FieldSchema(fieldName: 'number', columnName: 'number'),
    ],
    fields: [FieldSchema(fieldName: 'value', columnName: 'value')],
  );

  @override
  PrimaryKeyCodec<CompositeKey> get primaryKeyCodec =>
      const CompositePrimaryKeyCodec();

  @override
  bool get supportsAutomaticIdentity => false;

  @override
  ComplianceComposite fromJson(CompositeKey id, Map data) =>
      ComplianceComposite(id: id, value: data['value'] as String);

  @override
  Map<String, Object?> toJson(ComplianceCompositeData data) => {
    'value': data.value,
  };

  @override
  ComplianceComposite convert(
    ComplianceComposite model,
    ComplianceCompositeData data,
  ) => ComplianceComposite(id: model.id, value: data.value);

  @override
  ComplianceComposite fromData(
    ResolvedCreation<ComplianceCompositeData, CompositeKey> creation,
  ) => ComplianceComposite(id: creation.id, value: creation.data.value);

  @override
  CompositeKey identify(ComplianceComposite model) => model.id;
}

class ComplianceParentData {
  final String name;

  const ComplianceParentData({required this.name});
}

class ComplianceParent extends ComplianceParentData {
  final String id;
  final String profileId;

  const ComplianceParent({
    required this.id,
    required super.name,
    required this.profileId,
  });

  @override
  bool operator ==(Object other) =>
      other is ComplianceParent &&
      id == other.id &&
      name == other.name &&
      profileId == other.profileId;

  @override
  int get hashCode => Object.hash(id, name, profileId);
}

class ComplianceProfileData {
  final String label;

  const ComplianceProfileData({required this.label});
}

class ComplianceProfile extends ComplianceProfileData {
  final String id;

  const ComplianceProfile({required this.id, required super.label});

  @override
  bool operator ==(Object other) =>
      other is ComplianceProfile && id == other.id && label == other.label;

  @override
  int get hashCode => Object.hash(id, label);
}

class ComplianceChildData {
  final String parentId;
  final String label;

  const ComplianceChildData({required this.parentId, required this.label});
}

class ComplianceChild extends ComplianceChildData {
  final String id;

  const ComplianceChild({
    required this.id,
    required super.parentId,
    required super.label,
  });

  @override
  bool operator ==(Object other) =>
      other is ComplianceChild &&
      id == other.id &&
      parentId == other.parentId &&
      label == other.label;

  @override
  int get hashCode => Object.hash(id, parentId, label);
}

class ComplianceLinkData {
  final String parentId;
  final String profileId;

  const ComplianceLinkData({required this.parentId, required this.profileId});
}

class ComplianceLink extends ComplianceLinkData {
  final String id;

  const ComplianceLink({
    required this.id,
    required super.parentId,
    required super.profileId,
  });

  @override
  bool operator ==(Object other) =>
      other is ComplianceLink &&
      id == other.id &&
      parentId == other.parentId &&
      profileId == other.profileId;

  @override
  int get hashCode => Object.hash(id, parentId, profileId);
}

abstract class _SimpleEntity<Data, Model extends Data>
    implements Entity<Data, Model, String, SimpleCreation<Data, String>> {
  const _SimpleEntity({required this.schema});

  @override
  final EntitySchema schema;

  @override
  PrimaryKeyCodec<String> get primaryKeyCodec => const SinglePrimaryKeyCodec();

  @override
  bool get supportsAutomaticIdentity => true;

  @override
  String identify(Model model);

  @override
  Model fromJson(String id, Map data);

  @override
  Map<String, Object?> toJson(Data data);

  @override
  Model convert(Model model, Data data);

  @override
  Model fromData(ResolvedCreation<Data, String> creation);
}

class ComplianceParentEntity
    extends _SimpleEntity<ComplianceParentData, ComplianceParent> {
  const ComplianceParentEntity()
    : super(
        schema: const EntitySchema(
          tableName: 'dorm_compliance_parents',
          primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
          fields: [
            FieldSchema(fieldName: 'name', columnName: 'name'),
            FieldSchema(fieldName: 'profileId', columnName: 'profile_id'),
          ],
        ),
      );

  @override
  ComplianceParent fromJson(String id, Map data) => ComplianceParent(
    id: id,
    name: data['name'] as String,
    profileId: data['profile_id'] as String,
  );

  @override
  Map<String, Object?> toJson(ComplianceParentData data) => {
    'name': data.name,
    if (data is ComplianceParent) 'profile_id': data.profileId,
  };

  @override
  ComplianceParent convert(ComplianceParent model, ComplianceParentData data) =>
      ComplianceParent(
        id: model.id,
        name: data.name,
        profileId: model.profileId,
      );

  @override
  ComplianceParent fromData(
    ResolvedCreation<ComplianceParentData, String> creation,
  ) => ComplianceParent(
    id: creation.id,
    name: creation.data.name,
    profileId: creation.data is ComplianceParent
        ? (creation.data as ComplianceParent).profileId
        : '',
  );

  @override
  String identify(ComplianceParent model) => model.id;
}

class ComplianceProfileEntity
    extends _SimpleEntity<ComplianceProfileData, ComplianceProfile> {
  const ComplianceProfileEntity()
    : super(
        schema: const EntitySchema(
          tableName: 'dorm_compliance_profiles',
          primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
          fields: [FieldSchema(fieldName: 'label', columnName: 'label')],
        ),
      );

  @override
  ComplianceProfile fromJson(String id, Map data) =>
      ComplianceProfile(id: id, label: data['label'] as String);

  @override
  Map<String, Object?> toJson(ComplianceProfileData data) => {
    'label': data.label,
  };

  @override
  ComplianceProfile convert(
    ComplianceProfile model,
    ComplianceProfileData data,
  ) => ComplianceProfile(id: model.id, label: data.label);

  @override
  ComplianceProfile fromData(
    ResolvedCreation<ComplianceProfileData, String> creation,
  ) => ComplianceProfile(id: creation.id, label: creation.data.label);

  @override
  String identify(ComplianceProfile model) => model.id;
}

class ComplianceChildEntity
    extends _SimpleEntity<ComplianceChildData, ComplianceChild> {
  const ComplianceChildEntity()
    : super(
        schema: const EntitySchema(
          tableName: 'dorm_compliance_children',
          primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
          fields: [
            FieldSchema(fieldName: 'parentId', columnName: 'parent_id'),
            FieldSchema(fieldName: 'label', columnName: 'label'),
          ],
        ),
      );

  @override
  ComplianceChild fromJson(String id, Map data) => ComplianceChild(
    id: id,
    parentId: data['parent_id'] as String,
    label: data['label'] as String,
  );

  @override
  Map<String, Object?> toJson(ComplianceChildData data) => {
    'parent_id': data.parentId,
    'label': data.label,
  };

  @override
  ComplianceChild convert(ComplianceChild model, ComplianceChildData data) =>
      ComplianceChild(id: model.id, parentId: data.parentId, label: data.label);

  @override
  ComplianceChild fromData(
    ResolvedCreation<ComplianceChildData, String> creation,
  ) => ComplianceChild(
    id: creation.id,
    parentId: creation.data.parentId,
    label: creation.data.label,
  );

  @override
  String identify(ComplianceChild model) => model.id;
}

class ComplianceLinkEntity
    extends _SimpleEntity<ComplianceLinkData, ComplianceLink> {
  const ComplianceLinkEntity()
    : super(
        schema: const EntitySchema(
          tableName: 'dorm_compliance_links',
          primaryKeys: [FieldSchema(fieldName: 'id', columnName: 'id')],
          fields: [
            FieldSchema(fieldName: 'parentId', columnName: 'parent_id'),
            FieldSchema(fieldName: 'profileId', columnName: 'profile_id'),
          ],
        ),
      );

  @override
  ComplianceLink fromJson(String id, Map data) => ComplianceLink(
    id: id,
    parentId: data['parent_id'] as String,
    profileId: data['profile_id'] as String,
  );

  @override
  Map<String, Object?> toJson(ComplianceLinkData data) => {
    'parent_id': data.parentId,
    'profile_id': data.profileId,
  };

  @override
  ComplianceLink convert(ComplianceLink model, ComplianceLinkData data) =>
      ComplianceLink(
        id: model.id,
        parentId: data.parentId,
        profileId: data.profileId,
      );

  @override
  ComplianceLink fromData(
    ResolvedCreation<ComplianceLinkData, String> creation,
  ) => ComplianceLink(
    id: creation.id,
    parentId: creation.data.parentId,
    profileId: creation.data.profileId,
  );

  @override
  String identify(ComplianceLink model) => model.id;
}

class ComplianceFixtures<Q extends BaseQuery<Q>> {
  final BaseEngine<Q> engine;

  late final DatabaseEntity<
    ComplianceItemData,
    ComplianceItem,
    String,
    Q,
    SimpleCreation<ComplianceItemData, String>
  >
  items = DatabaseEntity(const ComplianceItemEntity(), engine: engine);

  late final DatabaseEntity<
    ComplianceParentData,
    ComplianceParent,
    String,
    Q,
    SimpleCreation<ComplianceParentData, String>
  >
  parents = DatabaseEntity(const ComplianceParentEntity(), engine: engine);

  late final DatabaseEntity<
    ComplianceProfileData,
    ComplianceProfile,
    String,
    Q,
    SimpleCreation<ComplianceProfileData, String>
  >
  profiles = DatabaseEntity(const ComplianceProfileEntity(), engine: engine);

  late final DatabaseEntity<
    ComplianceChildData,
    ComplianceChild,
    String,
    Q,
    SimpleCreation<ComplianceChildData, String>
  >
  children = DatabaseEntity(const ComplianceChildEntity(), engine: engine);

  late final DatabaseEntity<
    ComplianceLinkData,
    ComplianceLink,
    String,
    Q,
    SimpleCreation<ComplianceLinkData, String>
  >
  links = DatabaseEntity(const ComplianceLinkEntity(), engine: engine);

  late final DatabaseEntity<
    ComplianceCompositeData,
    ComplianceComposite,
    CompositeKey,
    Q,
    ExplicitCreation<ComplianceCompositeData, CompositeKey>
  >
  composites = DatabaseEntity(
    const ComplianceCompositeEntity(),
    engine: engine,
  );

  ComplianceFixtures(this.engine);
}
