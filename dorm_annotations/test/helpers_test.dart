import 'package:dorm_annotations/dorm_annotations.dart';
import 'package:test/test.dart';

enum _State { ready }

class _QualifiedValue {
  @override
  String toString() => 'Status.active';
}

void main() {
  test('normalizeText handles null and empty values', () {
    expect($normalizeText(null), isNull);
    expect($normalizeText(''), isEmpty);
  });

  test('normalizeText removes spaces, accents, and capitalization', () {
    expect($normalizeText('Olá, Ação'), 'OLA,ACAO');
  });

  test('normalizeDate returns a zero-padded calendar date', () {
    expect($normalizeDate(DateTime(2024, 2, 3)), '20240203');
    expect($normalizeDate(null), isNull);
  });

  test('normalizeEnum handles enum values', () {
    expect($normalizeEnum(_State.ready), 'ready');
  });

  test('normalizeEnum removes one class prefix from string values', () {
    expect($normalizeEnum(_QualifiedValue()), 'active');
    expect($normalizeEnum('A.B.C'), 'A.B.C');
    expect($normalizeEnum(null), isNull);
  });
}
