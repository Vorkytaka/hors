import 'package:hors/hors.dart';
import 'package:hors/src/recognizer/recognizer.dart';
import 'package:hors/src/token/token_parser.dart';

import '../data.dart';
import '../token/token_parsers.dart';

class PartOfDayRecognizer extends Recognizer {
  const PartOfDayRecognizer();

  @override
  RegExp get pattern => RegExp(
      r'(@)?f?([ravgdn])f?(@)?'); // (дата) (в/с) утром/днём/вечером/ночью (в/с) (дата)

  @override
  List<Token>? parse(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
    final preDate = match.group(1);
    final postDate = match.group(3);

    if (preDate == null && postDate == null) {
      return null;
    }

    int hourStart = 0;
    int hourEnd = 0;
    switch (match.group(2)) {
      case 'r': // morning
        hourStart = 5;
        hourEnd = 11;
        break;
      case 'a': // day
      case 'd':
        hourStart = 11;
        hourEnd = 15;
        break;
      case 'n': // noon
        hourStart = 12;
        hourEnd = 12;
        break;
      case 'v': // evening
        hourStart = 15;
        hourEnd = 23;
        break;
      case 'g': // night
        hourStart = 23;
        hourEnd = 5;
        break;
    }

    if (hourStart == 0) {
      return null;
    }

    final builder = AbstractDate.builder();
    builder.time = Duration(hours: hourStart);
    builder.fix(FixPeriod.timeUncertain);

    final int start;
    if (preDate != null) {
      start = tokens[1].start;
    } else {
      start = tokens.first.start;
    }

    final int end;
    if (postDate != null) {
      end = tokens[tokens.length - 2].end;
    } else {
      end = tokens.last.end;
    }

    if (hourStart == hourEnd) {
      return [
        if (preDate != null) tokens.first,
        DateToken(
          start: start,
          end: end,
          date: builder.build(),
        ),
        if (postDate != null) tokens.last,
      ];
    } else {
      final spanBuilder = AbstractDate.builder(time: Duration(hours: hourEnd));
      spanBuilder.fix(FixPeriod.timeUncertain);
      return [
        if (preDate != null) tokens.first,
        DateToken(start: start, end: end, date: builder.build()),
        TokenParsers.timeTo.toMaybeDateToken(start, end),
        DateToken(start: start, end: end, date: spanBuilder.build()),
        if (postDate != null) tokens.last,
      ];
    }
  }
}
