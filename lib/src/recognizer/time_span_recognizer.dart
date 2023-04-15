import 'package:hors/hors.dart';

import '../data.dart';
import 'recognizer.dart';

class TimeSpanRecognizer extends Recognizer {
  const TimeSpanRecognizer();

  @override
  RegExp get regexp => RegExp(
      r'(i)?((0?[Ymwdhe]N?)+)([bl])?'); // (через) год и месяц и 2 дня 4 часа 10 минут (спустя/назад)

  @override
  List<Token>? parser(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
    final prefix = match.group(1);
    final postfix = match.group(4);
    if (!((prefix != null) ^ (postfix != null))) {
      return null;
    }

    final int direction;
    if (postfix != null && postfix == 'b') {
      direction = -1;
    } else {
      direction = 1;
    }

    final builder = AbstractDate.builder();
    builder.spanDirection = direction;

    DateTime offset = fromDatetime.copyWith();
    final letters = match.group(2)?.split('') ?? const [];
    int lastNumber = 1;
    for (int i = 0; i < letters.length; i++) {
      // If we have (через) token
      final tokenIndex = prefix != null ? i + 1 : i;
      final token = tokens[tokenIndex];
      switch (token.symbol) {
        case '0':
          lastNumber = int.tryParse(token.text) ?? 1;
          break;
        case 'Y':
          offset = offset.copyWith(year: offset.year + direction * lastNumber);
          lastNumber = 1;
          builder.fixDownTo(FixPeriod.month);
          break;
        case 'm':
          offset =
              offset.copyWith(month: offset.month + direction * lastNumber);
          lastNumber = 1;
          builder.fixDownTo(FixPeriod.week);
          break;
        case 'w':
          offset = offset.add(Duration(days: 7 * direction * lastNumber));
          lastNumber = 1;
          builder.fixDownTo(FixPeriod.day);
          break;
        case 'd':
          offset = offset.add(Duration(days: direction * lastNumber));
          lastNumber = 1;
          builder.fixDownTo(FixPeriod.day);
          break;
        case 'h':
          offset = offset.add(Duration(hours: direction * lastNumber));
          lastNumber = 1;
          builder.fixDownTo(FixPeriod.time);
          break;
        case 'e':
          offset = offset.add(Duration(minutes: direction * lastNumber));
          lastNumber = 1;
          builder.fixDownTo(FixPeriod.time);
          break;
      }
    }

    builder.date = offset;
    if (builder.isFixed(FixPeriod.time)) {
      builder.time = Duration(hours: offset.hour, minutes: offset.minute);
    }
    builder.span = offset.difference(fromDatetime);

    return [
      DateToken(
        start: tokens.first.start,
        end: tokens.last.end,
        date: builder.build(),
      )
    ];
  }
}
