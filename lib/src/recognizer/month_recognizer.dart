import '../data.dart';
import '../domain.dart';
import '../token/token_parsers.dart';
import 'recognizer.dart';

class MonthRecognizer extends Recognizer {
  const MonthRecognizer();

  @override
  RegExp get regexp =>
      RegExp(r'([usxy])?M'); // [в] (прошлом|этом|следующем) марте

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;

    int year = fromDatetime.year;
    bool yearFixed = false;

    final monthTokenIndex = tokens.indexWhere(
      (token) => token.symbol == 'M',
      match.start,
    );
    final monthToken = tokens[monthTokenIndex];
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

    final dateToken = DateToken(
      start: tokens[match.start].start,
      end: tokens[match.end - 1].end,
    );
    dateToken.date = DateTime(year, month, 1);
    dateToken.fix(FixPeriod.month);
    if (yearFixed) dateToken.fix(FixPeriod.year);

    tokens.replaceRange(
      match.start,
      match.end,
      [dateToken],
    );

    return true;
  }
}
