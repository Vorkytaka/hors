import 'package:hors/hors.dart';
import 'package:hors/src/data.dart';
import 'package:hors/src/recognizer/recognizer.dart';
import 'package:hors/src/token/token_parser.dart';
import 'package:hors/src/token/token_parsers.dart';

class DayOfWeekRecognizer extends Recognizer {
  const DayOfWeekRecognizer();

  @override
  RegExp get pattern =>
      RegExp(r'([usxy])?(D)'); // [в] (следующий/этот/предыдущий) понедельник

  @override
  List<Token>? parse(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
    final dayOfWeekToken = tokens.firstWhere((token) => token.symbol == 'D');
    final dayOfWeek = TokenParsers.daysOfWeek.parseOrder(dayOfWeekToken.text);

    if (dayOfWeek == null) return null;

    final currentDayOfWeek = fromDatetime.weekday;
    int diff = dayOfWeek - currentDayOfWeek;

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
        start: tokens.first.start,
        end: tokens.last.end,
      ),
    ];
  }
}
