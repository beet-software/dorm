# `@ModelField`

Use `@ModelField` when a getter contains an embedded `@Data` or `@Model` value.

```dart title="lib/models.dart"
@ModelField(name: 'profile', referTo: _Profile)
get profile;
```

The annotation constructor is:

```dart
const ModelField({
  String? name,
  required Type referTo,
  ModelFieldTemplate<Object?> template =
      const ModelFieldTemplate<ModelFieldType>(),
})
```

- `name` is the stored field name. If omitted, the getter name is used.
- `referTo` identifies the annotated type represented by the field.
- `template` describes the generated field shape when a specific model-field
  template is required.

`ModelFieldTemplate<ModelFieldType>` keeps one generated value. Use a template
with a nullable or collection-shaped `ModelFieldType` when the nested value has
that shape:

```dart
@ModelField(
  name: 'profile',
  referTo: _Profile,
  template: ModelFieldTemplate<ModelFieldType?>(),
)
get profile;
```

```dart
@ModelField(
  name: 'students',
  referTo: _Student,
  template: ModelFieldTemplate<List<ModelFieldType>>(),
)
List get students;
```

The generator substitutes the type referenced by `referTo` for
`ModelFieldType`. For the examples above, the generated shapes are equivalent
to `Profile?` and `List<Student>` respectively. A list of nested values is
represented inside the containing model; it does not create a separate
repository or relationship path for each nested value.

These templates are most useful when the storage format represents structured
JSON or another non-relational composite value. They describe the shape of a
nested field; they do not create relational foreign keys. Use
[`@ForeignField`](foreign-field.md) when the value should reference a separate
stored model.
