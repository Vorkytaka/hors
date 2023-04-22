import 'package:hors/hors.dart';
import 'package:hors/src/utils.dart';

import '../data.dart';

class DayOfMonthRecognizer extends Recognizer {
  const DayOfMonthRecognizer();

  @override
  RegExp get regexp =>
      RegExp(r'((0N?)+)([M#])'); // 24, 25, 26... и 27 января/числа

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;

    bool monthFixed = false;

    final monthTokenIndex = tokens.indexWhere(
      (token) => token.symbol == 'M' || token.symbol == '#',
      match.start,
    );
    final monthToken = tokens[monthTokenIndex];
    int month = fromDatetime.month;
    for (final parser in TokenParsers.months) {
      final symbol = parser.parse(monthToken.text);
      if (symbol != null) {
        month = parser.order;
        monthFixed = true;
        break;
      }
    }

    final daysLength = match.group(1)?.length ?? 0;
    final List<DateToken> dates = [];

    final start = tokens[match.start].start;
    final end = tokens[match.end - 1].end;

    for (int i = 0; i < daysLength; i++) {
      final token = tokens[i + match.start];
      if (token.symbol != '0') {
        // that's not a number
        continue;
      }

      final day = int.parse(token.text);
      final validDay = getValidDayForMonth(fromDatetime.year, month, day);
      final dateToken = DateToken(
        start: start,
        end: end,
      );
      dateToken.date = DateTime(
        fromDatetime.year,
        month,
        validDay,
      );
      dateToken.fix(FixPeriod.week);
      dateToken.fix(FixPeriod.day);
      if (monthFixed) dateToken.fix(FixPeriod.month);

      // todo: maybe next month!

      dates.add(dateToken);
    }

    tokens.replaceRange(
      match.start,
      match.end,
      dates,
    );

    return true;
  }
}
