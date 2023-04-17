import 'package:hors/hors.dart';
import 'package:hors/src/data.dart';
import 'package:hors/src/token/token_parser.dart';

class DayOfWeekRecognizer extends Recognizer {
  const DayOfWeekRecognizer();

  @override
  RegExp get regexp =>
      RegExp(r'([usxy])?(D)'); // [в] (следующий/этот/предыдущий) понедельник

  @override
  List<Token>? parser(
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

    if (weekday == null) return null;

    final currentDayOfWeek = fromDatetime.weekday;
    int diff = weekday - currentDayOfWeek;

    final dateBuilder = AbstractDate.builder();

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
      dateBuilder.fixDownTo(FixPeriod.day);
    } else {
      dateBuilder.fix(FixPeriod.day);
      dateBuilder.fixDayOfWeek = true;
    }

    dateBuilder.date = fromDatetime.add(Duration(days: diff));

    return [
      DateToken(
        date: dateBuilder.build(),
        start: tokens[match.start].start,
        end: tokens[match.end - 1].end,
      ),
    ];
  }
}
