String? $normalizeText(String? value) {
  if (value == null) return null;
  if (value.isEmpty) return value;

  String result = value;

  // Remove spaces
  result = result.replaceAll(' ', '');

  // Remove accents
  const t0 = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
  const t1 = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
  for (int i = 0; i < t0.length; i++) {
    result = result.replaceAll(t0[i], t1[i]);
  }

  // Remove capitalization
  result = result.toUpperCase();

  return result;
}

String? $normalizeDate(DateTime? value) {
  if (value == null) return null;
  final int day = value.day;
  final int month = value.month;
  final int year = value.year;
  return '$year'.padLeft(4, '0') +
      '$month'.padLeft(2, '0') +
      '$day'.padLeft(2, '0');
}

String? $normalizeEnum(Object? value) {
  if (value == null) return null;
  if (value is Enum) return value.name;
  final List<String> tokens = '$value'.split('.');
  if (tokens.length == 2) return tokens.last;
  return tokens.join('.');
}
