import 'package:hors/src/data.dart';
import 'package:hors/src/hors.dart';
import 'package:hors/src/recognizer/recognizer.dart';
import 'package:hors/src/token/token_parsers.dart';
import 'package:hors/src/utils.dart';

class DatesPeriodRecognizer extends Recognizer {
  const DatesPeriodRecognizer();

  @override
  RegExp get regexp => RegExp(r'f?(0)[ot]0([M#])'); // с 26 до 27 января/числа

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

    int? dayIndex = tokens.indexWhere(
      (token) => token.symbol == '0',
      match.start,
    );
    final dayToken = tokens[dayIndex];
    int? day = int.tryParse(dayToken.text);
    if (day == null) {
      return false;
    }
    final validDay = getValidDayForMonth(fromDatetime.year, month, day);

    final dateToken = DateToken(
      start: dayToken.start,
      end: dayToken.end,
    );
    dateToken.date = DateTime(fromDatetime.year, month, validDay);
    dateToken.fix(FixPeriod.week);
    dateToken.fix(FixPeriod.day);
    if (monthFixed) dateToken.fix(FixPeriod.month);

    tokens[dayIndex] = dateToken;

    return true;
  }
}
