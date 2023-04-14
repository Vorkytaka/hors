import 'package:hors/hors.dart';
import 'package:hors/src/recognizer/recognizer.dart';
import 'package:hors/src/utils.dart';

import '../data.dart';
import '../token/token_parsers.dart';

class DayOfMonthRecognizer extends Recognizer {
  const DayOfMonthRecognizer();

  @override
  RegExp get regexp =>
      RegExp(r'((0N?)+)([M#])'); // 24, 25, 26... и 27 января/числа

  @override
  List<Token>? parser(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
    bool monthFixed = false;

    final monthToken = tokens
        .firstWhere((token) => token.symbol == 'M' || token.symbol == '#');
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
    for (int i = 0; i < daysLength; i++) {
      final token = tokens[i];
      if (token.symbol != '0') {
        // that's not a number
        continue;
      }

      final day = int.parse(token.text);
      final validDay = getValidDayForMonth(fromDatetime.year, month, day);
      final dateBuilder = AbstractDate.builder(
        date: DateTime(
          fromDatetime.year,
          month,
          validDay,
        ),
      );
      dateBuilder.fix(FixPeriod.week);
      dateBuilder.fix(FixPeriod.day);
      if (monthFixed) dateBuilder.fix(FixPeriod.month);

      // todo: maybe next month!

      dates.add(token.toDateToken(dateBuilder.build()));
    }

    return dates;
  }
}
