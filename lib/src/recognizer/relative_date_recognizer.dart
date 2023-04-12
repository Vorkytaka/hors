import 'package:hors/src/recognizer/recognizer.dart';

import '../../hors.dart';
import '../data.dart';

class RelativeDateRecognizer extends Recognizer {
  const RelativeDateRecognizer();

  @override
  RegExp get pattern => RegExp(
      r'([usxy])([Ymwd])'); // [в/на] следующей/этой/предыдущей год/месяц/неделе/день

  @override
  List<Token>? parse(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
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

    final builder = AbstractDate.builder();
    switch (match.group(2)) {
      case 'Y':
        builder.date =
            fromDatetime.copyWith(year: fromDatetime.year + direction);
        builder.fix(FixPeriod.year);
        break;
      case 'm':
        builder.date =
            fromDatetime.copyWith(month: fromDatetime.month + direction);
        builder.fixDownTo(FixPeriod.month);
        break;
      case 'w':
        builder.date = fromDatetime.add(Duration(days: direction * 7));
        builder.fixDownTo(FixPeriod.week);
        break;
      case 'd':
        builder.date = fromDatetime.add(Duration(days: direction));
        builder.fixDownTo(FixPeriod.day);
        break;
    }

    return [
      DateToken(
        start: tokens.first.start,
        end: tokens.last.end,
        date: builder.build(),
      )
    ];
  }
}
