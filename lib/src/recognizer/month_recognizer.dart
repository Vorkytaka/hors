import 'package:hors/hors.dart';
import 'package:hors/src/recognizer/recognizer.dart';

import '../data.dart';
import '../token/token_parsers.dart';

class MonthRecognizer extends Recognizer {
  const MonthRecognizer();

  @override
  RegExp get pattern =>
      RegExp(r'([usxy])?M'); // [в] (прошлом|этом|следующем) марте

  @override
  List<Token>? parse(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
    int year = fromDatetime.year;
    bool yearFixed = false;

    final monthToken = tokens.firstWhere((token) => token.symbol == 'M');
    int month = fromDatetime.month;
    for (final parser in TokenParsers.months) {
      final symbol = parser.parse(monthToken.text);
      if (symbol != null) {
        month = parser.order;
        break;
      }
    }

    final isMonthPast = month < fromDatetime.month;
    final isMonthFuture = month > fromDatetime.month;

    final relate = match.group(1);
    if (relate != null) {
      switch (relate) {
        case 'y':
          if (isMonthPast) year++;
          break;
        case 'x':
          if (!isMonthFuture) year++;
          break;
        case 's':
          if (!isMonthPast) year--;
          break;
      }

      yearFixed = true;
    }

    final dateBuilder = AbstractDate.builder(date: DateTime(year, month, 1));
    dateBuilder.fix(FixPeriod.month);
    if (yearFixed) dateBuilder.fix(FixPeriod.year);

    return [
      DateToken(
        start: tokens.first.start,
        end: tokens.last.end,
        date: dateBuilder.build(),
      )
    ];
  }
}
