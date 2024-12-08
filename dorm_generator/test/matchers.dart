import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'models.dart';
import 'proxy_matchers.dart';

abstract class BaseMatcher extends Matcher {
  const BaseMatcher();

  @protected
  bool shouldNotMatch(
    Map<Object?, Object?> matchState,
    String key,
    Map<String, Object?> value,
  ) {
    matchState['type'] = key;
    matchState['data'] = value;
    return false;
  }
}

class IsInstance<E> extends BaseMatcher {
  final List<MatcherProxy<E, Object?>> specs;

  const IsInstance([this.specs = const []]);

  @override
  Description describe(Description description) {
    return description.addAll(
      'should match all of:\n',
      '\n - ',
      '',
      specs.map((spec) => spec.child),
    );
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final String? suffix = switch (matchState) {
      {
        'type': 'invalid-type',
        'data': {'value': Object? value},
      } =>
        'expected $E, got ${value.runtimeType}',
      {
        'type': 'mismatch',
        'data': {
          'matcher': Matcher matcher,
          'value': Object? value,
          'matchState': Map<Object?, Object?> childMatchState,
        },
      } =>
        'value $value was not matched, because:\n${matcher.describeMismatch(
              value,
              StringDescription(),
              childMatchState,
              verbose,
            ).toString().splitMapJoin(
              RegExp(r'[^\n]+'),
              onMatch: (m) => '  ${m[0]}',
              onNonMatch: (t) => t,
            )}',
      _ => null,
    };
    if (suffix == null) {
      return super.describeMismatch(
        item,
        mismatchDescription,
        matchState,
        verbose,
      );
    }
    return mismatchDescription.add('[IsInstance<$E>]: ').add(suffix);
  }

  @override
  bool matches(item, Map matchState) {
    if (item is! E) {
      return shouldNotMatch(matchState, 'invalid-type', {'value': item});
    }
    if (specs.isEmpty) return true;
    for (MatcherProxy<E, Object?> spec in specs) {
      final Matcher matcher = spec.child;
      final Object? value = spec.access(item);
      final Object? token;
      if (value == null) {
        token = null;
      } else if (value is List<Object?>) {
        token = value.map(CodeToken.from).toList();
      } else {
        token = CodeToken.from(value);
      }
      final Map<Object?, Object?> childMatchState = {};
      if (matcher.matches(token, childMatchState)) {
        continue;
      }
      return shouldNotMatch(matchState, 'mismatch', {
        'matcher': matcher,
        'value': value,
        'matchState': childMatchState,
      });
    }
    return true;
  }
}

class IsElement<E extends Element> extends IsInstance<E> {
  const IsElement(super.specs);

  @override
  bool matches(item, Map matchState) {
    if (item is CodeToken) {
      switch (item) {
        case ElementToken(value: Element element):
          return super.matches(element, matchState);
        default:
      }
    }
    return super.matches(item, matchState);
  }
}

abstract class FieldMatcher<K> extends BaseMatcher {
  final K value;

  const FieldMatcher(this.value);

  K access(CodeToken token);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! CodeToken) {
      return shouldNotMatch(matchState, 'not-token', {'value': item});
    }
    final K actualValue = access(item);
    if (actualValue == value) {
      return true;
    }
    return shouldNotMatch(matchState, 'not-equal', {'value': actualValue});
  }

  @override
  Description describe(Description description) {
    return description.add('$runtimeType = "$value"');
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final String? suffix = switch (matchState) {
      {'type': 'not-token', 'data': {'value': Object? value}} =>
        'expected CodeToken, got ${value.runtimeType}',
      {'type': 'not-equal', 'data': {'value': Object? value}} =>
        'expected `${this.value}`, got `$value`',
      _ => null,
    };
    if (suffix == null) {
      return super.describeMismatch(
        item,
        mismatchDescription,
        matchState,
        verbose,
      );
    }
    return mismatchDescription.add('[$runtimeType]: ').add(suffix);
  }
}

class HasName extends FieldMatcher<String?> {
  const HasName(super.value);

  @override
  String? access(CodeToken token) => token.name;
}

class HasType extends FieldMatcher<String> {
  const HasType(super.value);

  @override
  String access(CodeToken token) {
    final DartType type = switch (token) {
      ElementToken(value: var element) => switch (element) {
          FunctionTypedElement(returnType: var t) => t,
          VariableElement(type: var t) => t,
          _ => throw InvalidElement(element),
        },
      TypeToken(value: var t) => t,
      AnnotationToken() => throw InvalidElement(value),
    };
    return type.getDisplayString();
  }
}

class HasBody extends FieldMatcher<String?> {
  const HasBody(super.value);

  @override
  String? access(CodeToken token) {
    switch (token) {
      case ElementToken(value: Element element):
        final Element? parentElement = element.enclosingElement;
        if (parentElement == null) return null;

        final String? sourceContent = element.source?.contents.data;
        if (sourceContent == null) return null;
        final ParseStringResult result = parseString(content: sourceContent);

        for (CompilationUnitMember declaration in result.unit.declarations) {
          final List<ClassMember>? members;
          switch (declaration) {
            case ExtensionDeclaration(
                onClause: ExtensionOnClause(
                  extendedType: TypeAnnotation type,
                ),
              ):
              if (parentElement is! ExtensionElement) continue;
              final String actualParentName = type.beginToken.value() as String;
              final String expectedParentName =
                  parentElement.extendedType.getDisplayString();
              if (actualParentName != expectedParentName) continue;
              members = declaration.members;
            case ClassDeclaration(name: Token token):
              if (parentElement is! ClassElement) continue;
              final String actualParentName = token.value() as String;
              final String expectedParentName = parentElement.name;
              if (actualParentName != expectedParentName) continue;
              members = declaration.members;
            default:
              continue;
          }
          for (ClassMember member in members) {
            final FunctionBody? body = switch (member) {
              ConstructorDeclaration(:FunctionBody body, name: Token? token)
                  when (token?.value() ?? '') == element.name =>
                body,
              ConstructorDeclaration() => null,
              MethodDeclaration(:FunctionBody body, name: Token? token)
                  when token.value() == element.name =>
                body,
              MethodDeclaration() => null,
              FieldDeclaration() => null,
            };
            if (body == null) {
              continue;
            }
            return body.toSource();
          }
        }
        return null;
      case TypeToken():
      case AnnotationToken():
        return null;
    }
  }
}

class HasElement extends BaseMatcher {
  final List<Matcher> children;

  const HasElement(this.children);

  @override
  Description describe(Description description) {
    for (int i = 0; i < children.length; i++) {
      final Matcher matcher = children[i];
      description =
          description.add(matcher.describe(StringDescription()).toString());
      if (i < children.length - 1) {
        description = description.add('\n');
      }
    }
    return description;
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final String? suffix = switch (matchState) {
      {
        'type': 'invalid-type',
        'data': {'value': Object? value},
      } =>
        'expected a CodeToken-able type, got $value',
      {
        'type': 'mismatch',
        'data': {
          'matcher': Matcher matcher,
          'item': Object? childItem,
          'matchState': Map<Object?, Object?> childMatchState,
        },
      } =>
        'value $childItem was not matched, because:\n${matcher.describeMismatch(
              childItem,
              StringDescription(),
              childMatchState,
              verbose,
            ).toString().splitMapJoin(
              RegExp(r'[^\n]+'),
              onMatch: (m) => '  ${m[0]}',
              onNonMatch: (t) => t,
            )}',
      _ => null,
    };
    if (suffix == null) {
      return super.describeMismatch(
        item,
        mismatchDescription,
        matchState,
        verbose,
      );
    }
    return mismatchDescription.add('[HasElement]: ').add(suffix);
  }

  @override
  bool matches(item, Map matchState) {
    final CodeToken token;
    try {
      token = CodeToken.from(item);
    } on InvalidElement {
      return shouldNotMatch(matchState, 'invalid-type', {'value': item});
    }
    for (Matcher matcher in children) {
      final Map<Object?, Object?> childMatchState = {};
      if (matcher.matches(token, childMatchState)) {
        continue;
      }
      return shouldNotMatch(matchState, 'mismatch', {
        'matcher': matcher,
        'item': item,
        'matchState': childMatchState,
      });
    }
    return true;
  }
}

class HasValues extends BaseMatcher {
  final List<Matcher> matchers;
  final String? key;

  const HasValues(this.matchers, {this.key});

  @override
  Description describe(Description description) {
    for (int i = 0; i < matchers.length; i++) {
      final Matcher matcher = matchers[i];
      final Description childDescription =
          matcher.describe(StringDescription());
      final List<String> childDescriptionLines =
          childDescription.toString().split('\n');
      for (int j = 0; j < childDescriptionLines.length; j++) {
        final String childDescriptionLine = childDescriptionLines[j];
        if (j == 0) {
          if (i < matchers.length - 1) {
            description.add('┣ ');
          } else {
            description.add('┗ ');
          }
        } else {
          if (i < matchers.length - 1) {
            description.add('┃  ');
          } else {
            description.add('   ');
          }
        }
        description.add(childDescriptionLine);
        description.add('\n');
      }
    }
    return description;
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final String? suffix = switch (matchState) {
      {
        'type': 'invalid-type',
        'data': {'value': Object? value},
      } =>
        'has a type of ${value.runtimeType}',
      {
        'type': 'invalid-length',
        'data': {'value': int length},
      } =>
        'expected ${matchers.length} elements, got $length',
      {
        'type': 'no-match',
        'data': {
          'value': Object? value,
          'mismatches': List<Map<String, Object?>> mismatches,
        },
      } =>
        '\n${mismatches.map((mismatchState) {
          return switch (mismatchState) {
            {
              'matcher': Matcher matcher,
              'matchState': Map<Object?, Object?> childMatchState,
            } =>
              matcher
                  .describeMismatch(
                    value,
                    StringDescription(),
                    childMatchState,
                    verbose,
                  )
                  .toString()
                  .splitMapJoin(
                    RegExp(r'[^\n]+'),
                    onMatch: (m) => '  ${m[0]}',
                    onNonMatch: (t) => t,
                  ),
            _ => 'XXXXXXXXXX',
          };
        }).join('\n')}',
      _ => null,
    };
    if (suffix == null) {
      return super.describeMismatch(
        item,
        mismatchDescription,
        matchState,
        verbose,
      );
    }
    return mismatchDescription.add('[${key ?? runtimeType}]: ').add(suffix);
  }

  @override
  bool matches(item, Map matchState) {
    if (item is! List<Object?>) {
      return shouldNotMatch(
        matchState,
        'invalid-type',
        {'value': item},
      );
    }
    final List<Object?> values = item;
    if (matchers.length != values.length) {
      return shouldNotMatch(
        matchState,
        'invalid-length',
        {'value': values.length},
      );
    }
    final Set<int> actualIndices = {};
    for (int tokenIdx = 0; tokenIdx < values.length; tokenIdx++) {
      final Object? value = values[tokenIdx];

      bool matched = false;
      final List<(Matcher, Map<Object?, Object?>)> mismatchStates = [];
      for (int matcherIdx = 0; matcherIdx < matchers.length; matcherIdx++) {
        if (actualIndices.contains(matcherIdx)) {
          continue;
        }
        final Matcher matcher = matchers[matcherIdx];

        final Map<Object?, Object?> childMatchState = {};
        if (matcher.matches(value, childMatchState)) {
          actualIndices.add(matcherIdx);
          matched = true;
          break;
        }
        mismatchStates.add((matcher, childMatchState));
      }
      if (!matched) {
        return shouldNotMatch(
          matchState,
          'no-match',
          {
            'value': value,
            'mismatches': [
              for (var (Matcher matcher, Map<Object?, Object?> childMatchState)
                  in mismatchStates)
                {
                  'matcher': matcher,
                  'matchState': childMatchState,
                },
            ],
          },
        );
      }
    }
    return true;
  }
}

class HasParameters extends HasValues {
  const HasParameters(super.matchers);

  @override
  bool matches(item, Map matchState) {
    if (item is! CodeToken) {
      return false;
    }
    return switch (item) {
      ElementToken(value: var element) => switch (element) {
          ConstructorElement(parameters: var p) => super.matches(p, matchState),
          FunctionTypedElement(parameters: var p) =>
            super.matches(p, matchState),
          _ => false,
        },
      TypeToken() => false,
      AnnotationToken() => false,
    };
  }
}
