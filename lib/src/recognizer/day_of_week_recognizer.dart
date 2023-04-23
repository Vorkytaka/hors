import '../data.dart';
import '../token/token_parser.dart';
import '../token/token_parsers.dart';
import 'recognizer.dart';

class DayOfWeekRecognizer extends Recognizer {
  const DayOfWeekRecognizer();

  @override
  RegExp get regexp =>
      RegExp(r'([usxy])?(D)'); // [в] (следующий/этот/предыдущий) понедельник

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;
    final weekdayTokenIndex = tokens.indexWhere(
      (token) => token.symbol == 'D',
      match.start,
    );
    final weekdayToken = tokens[weekdayTokenIndex];
    final weekday = TokenParsers.daysOfWeek.parseOrder(weekdayToken.text);

    if (weekday == null) return false;

    final currentDayOfWeek = fromDatetime.weekday;
    int diff = weekday - currentDayOfWeek;

    final dateToken = DateToken(
      start: tokens[match.start].start,
      end: tokens[match.end - 1].end,
    );

    final relate = match.group(1);
    if (relate != null) {
      switch (relate) {
        case 'y': // Closest next
          if (diff < 0) diff += 7;
          break;
        case 'x': // Next
          diff += 7;
          break;
        case 's': // Previous
          diff -= 7;
          break;
      }
      dateToken.fixDownTo(FixPeriod.day);
    } else {
      dateToken.fix(FixPeriod.day);
      dateToken.fixDayOfWeek = true;
    }

    dateToken.date = fromDatetime.add(Duration(days: diff));

    tokens.replaceRange(
      match.start,
      match.end,
      [dateToken],
    );

    return true;
  }
}
