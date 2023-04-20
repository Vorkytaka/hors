import 'package:hors/hors.dart';

import '../data.dart';

class TimeSpanRecognizer extends Recognizer {
  const TimeSpanRecognizer();

  @override
  RegExp get regexp => RegExp(
      r'(i)?((0?[Ymwdhe]N?)+)([bl])?'); // (через) год и месяц и 2 дня 4 часа 10 минут (спустя/назад)

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;

    final prefix = match.group(1);
    final postfix = match.group(4);
    if (!((prefix != null) ^ (postfix != null))) {
      return false;
    }

    final int direction;
    if (postfix != null && postfix == 'b') {
      direction = -1;
    } else {
      direction = 1;
    }

    final dateToken = DateToken(
      start: tokens[match.start].start,
      end: tokens[match.end - 1].end,
    );
    dateToken.spanDirection = direction;

    DateTime offset = fromDatetime.copyWith();
    final letters = match.group(2)?.split('') ?? const [];
    int lastNumber = 1;
    for (int i = 0; i < letters.length; i++) {
      // If we have (через) token
      final tokenIndex = prefix != null ? i + 1 : i;
      final token = tokens[tokenIndex + match.start];
      switch (token.symbol) {
        case '0':
          lastNumber = int.tryParse(token.text) ?? 1;
          break;
        case 'Y':
          offset = offset.copyWith(year: offset.year + direction * lastNumber);
          lastNumber = 1;
          dateToken.fixDownTo(FixPeriod.month);
          break;
        case 'm':
          offset =
              offset.copyWith(month: offset.month + direction * lastNumber);
          lastNumber = 1;
          dateToken.fixDownTo(FixPeriod.week);
          break;
        case 'w':
          offset = offset.add(Duration(days: 7 * direction * lastNumber));
          lastNumber = 1;
          dateToken.fixDownTo(FixPeriod.day);
          break;
        case 'd':
          offset = offset.add(Duration(days: direction * lastNumber));
          lastNumber = 1;
          dateToken.fixDownTo(FixPeriod.day);
          break;
        case 'h':
          offset = offset.add(Duration(hours: direction * lastNumber));
          lastNumber = 1;
          dateToken.fixDownTo(FixPeriod.time);
          break;
        case 'e':
          offset = offset.add(Duration(minutes: direction * lastNumber));
          lastNumber = 1;
          dateToken.fixDownTo(FixPeriod.time);
          break;
      }
    }

    dateToken.date = offset;
    if (dateToken.isFixed(FixPeriod.time)) {
      dateToken.time = Duration(hours: offset.hour, minutes: offset.minute);
    }
    dateToken.span = offset.difference(fromDatetime);

    tokens.replaceRange(
      match.start,
      match.end,
      [dateToken],
    );

    return true;
  }
}
