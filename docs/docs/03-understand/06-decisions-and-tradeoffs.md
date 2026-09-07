# Why familiar dORM behaviors work this way

This page records decisions and principles explicitly confirmed by the author. It separates deliberate behavior from preferences, limitations, accidental behavior, and historical artifacts.

## Read the status of each statement

| Status | Meaning in this page |
| --- | --- |
| Deliberate decision | The author confirmed the behavior as intended |
| Deliberate trade-off | The author confirmed the behavior and the capability or cost accepted with it |
| Preference or principle | The author stated a preferred direction; it is not automatically a runtime guarantee |
| Limitation | The current behavior is incomplete or blocked, and is not classified as a permanent exclusion |
| Accidental behavior | The author explicitly said the current behavior is not intended |
| Historical artifact | The behavior remains from an earlier API or backend-specific implementation |

## Use `Engine` as the `Dorm` construction boundary

**Status: Deliberate decision.**

Generated `Dorm` receives a `BaseEngine`. The engine creates the reference and relationship implementations used by generated database entities. The author identifies direct `BaseReference` construction as the former API shape and classifies the old README wording as historical.

For current application code, construct the concrete engine and pass it to generated `Dorm`:

```dart
final Dorm dorm = Dorm(Engine());
```

The trade-off is that direct construction of a concrete reference is not the current construction path.

## Keep framework contracts as the common denominator

**Status: Deliberate trade-off, partially deliberate.**

`BaseEngine`, `BaseReference`, `BaseRelationship`, and `BaseQuery` define the common layer. BLoC, Firebase, and MySQL implement those contracts with different storage and capability behavior.

This prioritizes portable application code over exposing every backend internals through one common API. Concrete engine customization outside the confirmed framework and barrel surfaces is not a current public guarantee.

## Separate `Data`, `Model`, and `Dependency`

**Status: Deliberate decision.**

`Data` is the input shape used for forms and creation. `Model` represents the identified persisted object and carries relationship fields. `Dependency` carries the related identities required to construct a model.

The trade-off is that application code uses several generated types instead of one universal persistence/input type. In return, `put` can compose `Data` and `Dependency` internally while `push` accepts an identified `Model`.

## Keep `put` and `push` as separate operations

**Status: Deliberate trade-off, partially deliberate.**

`put` creates a model from `Data` and `Dependency`. `push` writes an already identified `Model`. The author confirmed this distinction so creation-side code can provide `Data` without merging relationship dependencies itself.

The accepted trade-off is a larger operation vocabulary and engine-specific conflict behavior behind those operations. The distinction is visible in [Create, read, update, and remove store records](../02-build-the-store/01-crud.md).

## Preserve String UUID identity behavior

**Status: Deliberate trade-off with a historical compatibility reason and an author-stated preference.**

String remains the default identity shape because it originated with Firebase and was retained for compatibility. Current BLoC and MySQL implementations generate UUID strings, and Firebase uses String push keys.

The author also states a preference for UUIDs because models can receive identities without a centralized allocator. The trade-off is that the default remains tied to the historical String shape while engines still impose different identity restrictions.

## Treat relation names and generated names as public API

**Status: Deliberate decisions.**

`ForeignField.as` and `ForeignField.inverseAs` control generated client-facing relation names. Generated names such as `UserData`, `UserEntity`, `UserFields`, dependencies, relation accessors, and `Dorm` accessors are considered public and stable.

The consequence is that changing an explicit relation name or generated naming rule can change application source compatibility. The generated names are part of the surface used by the store examples and tests.

## Keep `ForeignField.unique` as ORM cardinality metadata

**Status: Deliberate decision.**

`ForeignField.unique` marks relationship cardinality in ORM metadata. It distinguishes relationship forms such as one-to-one and one-to-many; it does not cause the MySQL schema generator to emit a physical database uniqueness constraint.

The trade-off is that relationship meaning and physical database enforcement remain separate concerns.

## Allow relation plans and readable fallbacks

**Status: Deliberate trade-off.**

`TableRelationPlan` and `CompositeRelationPlan` provide structural information that an engine may optimize. Readable repository operations and callback-based relationships remain available when a direct plan cannot be used.

The trade-off is a relationship layer with more than one execution form. Engines can batch or join compatible sources, while custom implementations may need to support both plan-aware and readable paths.

## Preserve generated relationship-path result shapes

**Status: Deliberate decision.**

Generated relation paths have contract-level result semantics:

- required to-one paths omit parents without a target;
- nullable to-one paths preserve parents with `null`;
- to-many paths flatten related values and omit parents without targets;
- empty-preserving to-many paths return an empty list for those parents.

The author confirmed that these shapes should be equivalent across implementations. Engines therefore lose freedom to expose a different shape for the same generated path.

## Keep realtime observation best-effort

**Status: Deliberate trade-off.**

The common API exposes `pull` and `pullAll`, but not every engine can provide continuous events. BLoC and Firebase currently emit subsequent state/value events; MySQL currently performs an initial read and marks realtime behavior as incomplete.

The trade-off preserves one observation vocabulary across engines while not guaranteeing live updates for every backend. The current engine differences are shown in [Choose a dORM engine](../03-apply/01-choose-an-engine.md).

## Keep current limitations distinct from permanent design rules

**Status: Limitations, not confirmed permanent exclusions.**

The author classifies public transactions as an intended capability that is
currently missing or blocked. Offset pagination is now implemented through the
common repository surface; cursor pagination remains unsupported. Batch
atomicity is desired but incomplete across engines. Filter portability is
desired, but the current API may need improvement. These statuses do not turn
an implementation gap into a permanent design principle.

The author also classifies composite-key restrictions as accidental and identifies the current polymorphic representation as requiring review for non-JSON engines. Derived fields are the current generated persisted-value API; they do not create indexes automatically.

## Treat common abstractions as focused rather than complete

**Status: Preference or principle with a deliberate trade-off.**

The author states that the common abstraction should cover ordinary cases while exceptional or backend-specific cases may leave it. Ordinary application code is expected to use framework concepts; backend-specific access is an explicit exception.

The trade-off is a smaller common abstraction instead of a single API containing every database capability. This principle does not classify every missing feature as deliberate; each limitation keeps its own status.
