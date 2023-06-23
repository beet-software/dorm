// dORM
// Copyright (C) 2023  Beet Software
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
