import '../../hors.dart';
import '../data.dart';
import '../domain.dart';

class RelativeDateRecognizer extends Recognizer {
  const RelativeDateRecognizer();

  @override
  RegExp get regexp => RegExp(
      r'([usxy])([Ymwd])'); // [в/на] следующей/этой/предыдущей год/месяц/неделе/день

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;

    final int direction;
    switch (match.group(1)) {
      case 'y':
      case 'x':
        direction = 1;
        break;
      case 's':
        direction = -1;
        break;
      default:
        direction = 0;
        break;
    }

    final dateToken = DateToken(
      start: tokens[match.start].start,
      end: tokens[match.end - 1].end,
    );
    switch (match.group(2)) {
      case 'Y':
        dateToken.date =
            fromDatetime.copyWith(year: fromDatetime.year + direction);
        dateToken.fix(FixPeriod.year);
        break;
      case 'm':
        dateToken.date =
            fromDatetime.copyWith(month: fromDatetime.month + direction);
        dateToken.fixDownTo(FixPeriod.month);
        break;
      case 'w':
        dateToken.date = fromDatetime.add(Duration(days: direction * 7));
        dateToken.fixDownTo(FixPeriod.week);
        break;
      case 'd':
        dateToken.date = fromDatetime.add(Duration(days: direction));
        dateToken.fixDownTo(FixPeriod.day);
        break;
    }

    tokens.replaceRange(
      match.start,
      match.end,
      [dateToken],
    );

    return true;
  }
}
