import 'dart:math';

import 'data.dart';

extension TokenListUtils on List<Token> {
  // ignore: provide_deprecation_message
  @deprecated
  String get toPattern => map((e) => e.symbol).join();
}

int getValidDayForMonth(int year, int month, int day) {
  final inMonth = getDaysInMonth(year, month);
  return max(1, min(day, inMonth));
}

int getDaysInMonth(int year, int month) {
  if (month == DateTime.february) {
    final bool isLeapYear =
        (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
    return isLeapYear ? 29 : 28;
  }
  const List<int> daysInMonth = <int>[
    31,
    -1,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  ];
  return daysInMonth[month - 1];
}
