# Delete records

Choose the removal operation by the scope of the deletion. Each operation
targets the repository for one entity.

## Remove one identity

```dart
await dorm.users.repository.pop(created.id);
```

Removing an identity that is not present does not produce a model result.

## Remove several identities

```dart
await dorm.users.repository.popKeys([
  'user-id-1',
  'user-id-2',
]);
```

`popKeys` removes the supplied identities. Composite identities use the
identity representation generated for that entity.

## Remove matching records

```dart
await dorm.users.repository.popAll(
  Filter.value(
    'ada@example.org',
    field: UserEntity.fields.email,
  ),
);
```

`popAll` applies the filter through the selected engine. The execution details
and atomicity of filtered removal can differ by backend.

## Remove every record

```dart
await dorm.users.repository.purge();
```

Use `purge` only when the application intends to clear the repository's entire
entity collection. It is different from a filtered deletion because it does
not receive a filter.

After removing data, a later `peek` returns `null` for a removed identity and a
collection read no longer includes it. Stream behavior after removal depends on
the selected engine; see [Read records](reading.md).
