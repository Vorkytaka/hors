import 'package:hors/hors.dart';
import 'package:hors/src/token/token_parser.dart';

import '../data.dart';

class TimeRecognizer extends Recognizer {
  const TimeRecognizer();

  @override
  RegExp get regexp => RegExp(
      r'([rvgd])?([fot])?([QH])?(h|(0)(h)?)((0)e?)?([rvgd])?'); // (в/с/до) (половину/четверть) час/9 (часов) (30 (минут)) (утра/дня/вечера/ночи)

  @override
  List<Token>? parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;

    final prePartOfDay = match.group(1);
    final number = match.group(5);
    final postPartOfDay = match.group(9);

    if (prePartOfDay == null &&
        match.group(4) == null &&
        number == null &&
        match.group(6) == null &&
        postPartOfDay == null) {
      return null;
    }

    if (number == null) {
      final String? partOfDay = postPartOfDay ?? prePartOfDay;

      // no part of day AND no "from" token in phrase, quit
      if (partOfDay != 'd' && partOfDay != 'g' && match.group(2) == null) {
        return null;
      }
    }

    final hoursTokenIndex = tokens.indexWhere(
      (token) => token.symbol == '0',
      match.start,
    );
    int hours;
    if (hoursTokenIndex >= 0) {
      final hoursToken = tokens[hoursTokenIndex];
      hours = int.tryParse(hoursToken.text) ?? 1;
    } else {
      hours = 1;
    }

    if (hours < 0 || hours > 23) {
      return null;
    }

    int minutes = 0;
    final minutesTokenIndex = tokens.indexWhere(
      (token) => token.symbol == '0',
      hoursTokenIndex + 1,
    );
    if (minutesTokenIndex >= 0) {
      final minutesToken = tokens[minutesTokenIndex];
      final m = int.tryParse(minutesToken.text);
      if (m != null && m >= 0 && m <= 59) {
        minutes = m;
      }
    } else if (match.group(3) != null && hours > 0) {
      switch (match.group(3)) {
        case "Q": // quarter
          hours--;
          minutes = 15;
          break;
        case "H": // half
          hours--;
          minutes = 30;
          break;
      }
    }

    final builder = AbstractDate.builder();
    builder.fix(FixPeriod.timeUncertain);
    if (hours > 12) builder.fix(FixPeriod.time);

    if (hours <= 12) {
      final String part = prePartOfDay ?? postPartOfDay ?? 'd';
      if (prePartOfDay != null || postPartOfDay != null) {
        builder.fix(FixPeriod.time);
      }

      switch (part) {
        case "d": // day
          if (hours <= 4) hours += 12;
          break;
        case "v": // evening
          if (hours <= 11) hours += 12;
          break;
        case "g": // night
          if (hours >= 10) hours += 12;
          break;
      }

      if (hours >= 24) hours -= 24;
    }

    builder.time = Duration(hours: hours, minutes: minutes);

    final start = tokens[match.start].start;
    final end = tokens[match.end - 1].end;
    return [
      if (match.group(2) == 't')
        TokenParsers.timeTo.toMaybeDateToken(start, end),
      DateToken(start: start, end: end, date: builder.build()),
    ];
  }
}
