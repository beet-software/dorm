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

/// Removes spaces, replace diacritics and capitalization for a [value].
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

/// Formats a [value] as "YYYYMMDD".
String? $normalizeDate(DateTime? value) {
  if (value == null) return null;
  final int day = value.day;
  final int month = value.month;
  final int year = value.year;
  return '$year'.padLeft(4, '0') +
      '$month'.padLeft(2, '0') +
      '$day'.padLeft(2, '0');
}

/// Formats a [value] as "YYYYMMDDHHmmssSSS".
String? $normalizeDateTime(DateTime? value) {
  if (value == null) return null;
  final String date = $normalizeDate(value)!;
  final String hour = '${value.hour}'.padLeft(2, '0');
  final String minute = '${value.minute}'.padLeft(2, '0');
  final String second = '${value.second}'.padLeft(2, '0');
  final String millisecond = '${value.millisecond}'.padLeft(3, '0');
  return '$date$hour$minute$second$millisecond';
}

/// Removes the `Class.` component of a [value] string-formatted as `Class.value`.
String? $normalizeEnum(Object? value) {
  if (value == null) return null;
  if (value is Enum) return value.name;
  final List<String> tokens = '$value'.split('.');
  if (tokens.length == 2) return tokens.last;
  return tokens.join('.');
}
