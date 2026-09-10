import 'package:dorm_framework/dorm_framework.dart';
import 'package:test/test.dart';

class _Query extends BaseQuery<_Query> {
  final List<String> operations;

  _Query([this.operations = const []]);

  _Query _record(String operation) => _Query([...operations, operation]);

  @override
  _Query whereValue(String key, Object? value) {
    return _record('value:$key=$value');
  }

  @override
  _Query whereText(String key, String prefix) {
    return _record('text:$key=$prefix');
  }

  @override
  _Query whereDate(String key, DateTime date, DateFilterUnit unit) {
    return _record('date:$key=$date:${unit.name}');
  }

  @override
  _Query whereRange<R>(String key, FilterRange<R> range) {
    return _record('range:$key=${range.from}:${range.to}');
  }

  @override
  _Query limit(int count) => _record('limit:$count');

  @override
  _Query offset(int count) => _record('offset:$count');

  @override
  _Query sorted(String key, {bool ascending = true}) => _record('sort:$key');
}

class _AdvancedQuery
    implements
        ComparisonQuery<_AdvancedQuery>,
        LogicalQuery<_AdvancedQuery>,
        NegationQuery<_AdvancedQuery>,
        CollectionQuery<_AdvancedQuery> {
  final List<String> operations;

  _AdvancedQuery([this.operations = const []]);

  _AdvancedQuery _advanced(String operation) =>
      _AdvancedQuery([...operations, operation]);

  @override
  _AdvancedQuery whereValue(String key, Object? value) =>
      _advanced('value:$key=$value');

  @override
  _AdvancedQuery whereText(String key, String prefix) =>
      _advanced('text:$key=$prefix');

  @override
  _AdvancedQuery whereDate(String key, DateTime date, DateFilterUnit unit) =>
      _advanced('date:$key=$date:${unit.name}');

  @override
  _AdvancedQuery whereRange<R>(String key, FilterRange<R> range) =>
      _advanced('range:$key=${range.from}:${range.to}');

  @override
  _AdvancedQuery limit(int count) => _advanced('limit:$count');

  @override
  _AdvancedQuery offset(int count) => _advanced('offset:$count');

  @override
  _AdvancedQuery sorted(String key, {bool ascending = true}) =>
      _advanced('sort:$key');

  @override
  _AdvancedQuery whereComparison(
    String key,
    FilterComparisonOperator operator,
    Object? value,
  ) => _advanced('comparison:$key:${operator.name}=$value');

  @override
  _AdvancedQuery whereSet(
    String key,
    Iterable<Object?> values, {
    required bool negated,
  }) => _advanced('set:$key:${values.join(',')}:$negated');

  @override
  _AdvancedQuery whereNull(String key, {required bool isNull}) =>
      _advanced('null:$key=$isNull');

  @override
  _AdvancedQuery whereAll(Iterable<BaseFilter> filters) =>
      _advanced('all:${filters.length}');

  @override
  _AdvancedQuery whereAny(Iterable<BaseFilter> filters) =>
      _advanced('any:${filters.length}');

  @override
  _AdvancedQuery whereNot(BaseFilter filter) => _advanced('not');

  @override
  _AdvancedQuery whereContains(String key, Object? value) =>
      _advanced('contains:$key=$value');

  @override
  _AdvancedQuery whereContainsAny(String key, Iterable<Object?> values) =>
      _advanced('containsAny:$key=${values.join(',')}');
}

void main() {
  test('empty filter leaves the query unchanged', () {
    final _Query query = _Query();

    expect(const BaseFilter<_Query>.empty().accept(query), same(query));
  });

  test('value filter resolves a FieldSchema column name', () {
    const FieldSchema field = FieldSchema(
      fieldName: 'schoolId',
      columnName: 'school_id',
    );

    final _Query query = const BaseFilter<_Query>.value(
      7,
      field: field,
    ).accept(_Query());

    expect(query.operations, ['value:school_id=7']);
    expect(
      (const BaseFilter<_Query>.value(7, field: field) as ValueFilter<_Query>)
          .field
          .fieldName,
      'schoolId',
    );
  });

  test('text, date, and range filters delegate to the query', () {
    final DateTime date = DateTime(2024, 2, 3, 4, 5, 6);
    final _Query query =
        const BaseFilter<_Query>.text(
              'Ada',
              field: FieldSchema(fieldName: 'name', columnName: 'name'),
            )
            .accept(_Query())
            .whereDate('created_at', date, DateFilterUnit.day)
            .whereRange('score', const FilterRange<double>(from: 1, to: 10));

    expect(query.operations, [
      'text:name=Ada',
      'date:created_at=$date:day',
      'range:score=1.0:10.0',
    ]);
  });

  test('range filter factories preserve their range types and values', () {
    final _Query text = BaseFilter<_Query>.textRange(
      const FilterRange<String>(from: 'A', to: 'M'),
      field: FieldSchema(fieldName: 'name', columnName: 'name'),
    ).accept(_Query());
    final _Query numeric = BaseFilter<_Query>.numericRange(
      const FilterRange<double>(from: 1, to: 10),
      field: FieldSchema(fieldName: 'score', columnName: 'score'),
    ).accept(_Query());
    final _Query date = BaseFilter<_Query>.dateRange(
      DateFilterRange(
        from: DateTime(2024),
        to: DateTime(2025),
        unit: DateFilterUnit.year,
      ),
      field: FieldSchema(fieldName: 'createdAt', columnName: 'created_at'),
    ).accept(_Query());

    expect(text.operations, ['range:name=A:M']);
    expect(numeric.operations, ['range:score=1.0:10.0']);
    expect(date.operations, [
      'range:created_at=2024-01-01 00:00:00.000:2025-01-01 00:00:00.000',
    ]);
  });

  test('date filter preserves its selected unit', () {
    final DateTime value = DateTime(2024, 2, 3);
    final _Query query = BaseFilter<_Query>.date(
      value,
      field: const FieldSchema(
        fieldName: 'createdAt',
        columnName: 'created_at',
      ),
      unit: DateFilterUnit.month,
    ).accept(_Query());

    expect(query.operations, ['date:created_at=$value:month']);
  });

  test('rebuilds a backend filter from its structured expression', () {
    final BaseFilter<_Query> filter = BaseFilter.fromExpression(
      const ValueFilterExpression('status', 'active'),
    );

    expect(filter.accept(_Query()).operations, ['value:status=active']);
  });
  test('query options are applied after the filter', () {
    final _Query query =
        const QueryOptions(
          orderBy: [
            OrderBy(FieldSchema(fieldName: 'name', columnName: 'name')),
          ],
          limit: 5,
        ).apply(
          const BaseFilter<_Query>.value(
            true,
            field: FieldSchema(fieldName: 'active', columnName: 'active'),
          ).accept(_Query()),
        );

    expect(query.operations, ['value:active=true', 'sort:name', 'limit:5']);
  });

  test('date filter units expose their corresponding date component', () {
    final DateTime date = DateTime(2024, 2, 3, 4, 5, 6, 7);

    expect(DateFilterUnit.year.access(date), 2024);
    expect(DateFilterUnit.month.access(date), 2);
    expect(DateFilterUnit.day.access(date), 3);
    expect(DateFilterUnit.hour.access(date), 4);
    expect(DateFilterUnit.minute.access(date), 5);
    expect(DateFilterUnit.second.access(date), 6);
    expect(DateFilterUnit.milliseconds.access(date), 7);
  });

  test(
    'comparison, set, null, and collection filters use query capabilities',
    () {
      const FieldSchema field = FieldSchema(
        fieldName: 'status',
        columnName: 'status',
      );

      final _AdvancedQuery query = BaseFilter.notEqual<_AdvancedQuery>(
        'archived',
        field: field,
      ).accept(_AdvancedQuery());
      expect(query.operations, ['comparison:status:notEqual=archived']);

      final _AdvancedQuery setQuery = BaseFilter.inValues<_AdvancedQuery>(
        const ['active', 'pending'],
        field: field,
      ).accept(_AdvancedQuery());
      expect(setQuery.operations, ['set:status:active,pending:false']);

      final _AdvancedQuery nullQuery = BaseFilter.isNull<_AdvancedQuery>(
        field: field,
      ).accept(_AdvancedQuery());
      expect(nullQuery.operations, ['null:status=true']);

      final _AdvancedQuery collectionQuery =
          BaseFilter.contains<_AdvancedQuery>(
            'dart',
            field: field,
          ).accept(_AdvancedQuery());
      expect(collectionQuery.operations, ['contains:status=dart']);
    },
  );

  test('logical filters preserve their child structure', () {
    const FieldSchema field = FieldSchema(
      fieldName: 'status',
      columnName: 'status',
    );
    final BaseFilter<_AdvancedQuery> first = BaseFilter.value(
      'active',
      field: field,
    );
    final BaseFilter<_AdvancedQuery> second = BaseFilter.value(
      'pending',
      field: field,
    );

    expect(
      BaseFilter.allOf<_AdvancedQuery>([
        first,
        second,
      ]).accept(_AdvancedQuery()).operations,
      ['all:2'],
    );
    expect(
      BaseFilter.anyOf<_AdvancedQuery>([
        first,
        second,
      ]).accept(_AdvancedQuery()).operations,
      ['any:2'],
    );
    expect(
      BaseFilter.not<_AdvancedQuery>(first).accept(_AdvancedQuery()).operations,
      ['not'],
    );
  });

  test('anyOf rejects an empty filter list', () {
    expect(
      () => BaseFilter.anyOf<_AdvancedQuery>(const []),
      throwsArgumentError,
    );
  });

  test(
    'allOf empty is the identity filter and filters compare structurally',
    () {
      const FieldSchema field = FieldSchema(
        fieldName: 'status',
        columnName: 'status',
      );
      final BaseFilter<_AdvancedQuery> empty = BaseFilter.allOf<_AdvancedQuery>(
        const [],
      );
      expect(empty.accept(_AdvancedQuery()).operations, isEmpty);

      final BaseFilter<_AdvancedQuery> left =
          BaseFilter.inValues<_AdvancedQuery>(const [
            'active',
            'pending',
          ], field: field);
      final BaseFilter<_AdvancedQuery> right =
          BaseFilter.inValues<_AdvancedQuery>(const [
            'active',
            'pending',
          ], field: field);
      expect(left, right);
      expect(left.hashCode, right.hashCode);
      expect(left.expression, isA<SetFilterExpression>());
    },
  );
}
