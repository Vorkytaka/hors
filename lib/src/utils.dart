import 'dart:math';

import 'data.dart';

extension TokenListUtils on List<Token> {
  String get toPattern => map((e) => e.symbol).join();
}

extension RegExpUtils on RegExp {
  List<Token>? matchThrough(
    List<Token> tokens,
    List<Token>? Function(Match match, List<Token> tokens) onFound,
  ) {
    tokens = [...tokens];
    final pattern = tokens.toPattern;
    RegExpMatch? match = firstMatch(pattern);

    if (match == null) return null;

    int lastStart = 0;
    do {
      final foundMatch = match!;

      // do it!
      final newTokens =
          onFound(foundMatch, tokens.sublist(foundMatch.start, foundMatch.end));

      if (newTokens != null && newTokens.isNotEmpty) {
        tokens.replaceRange(foundMatch.start, foundMatch.end, newTokens);
      }

      lastStart = foundMatch.end;
      match = firstMatch(pattern.substring(lastStart));
    } while (lastStart < pattern.length && match != null);

    return tokens;
  }
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
