import 'package:hors/hors.dart';
import 'package:hors/src/token/token_parser.dart';

import '../data.dart';

class PartOfDayRecognizer extends Recognizer {
  const PartOfDayRecognizer();

  @override
  RegExp get regexp => RegExp(
      r'(@)?f?([ravgdn])f?(@)?'); // (дата) (в/с) утром/днём/вечером/ночью (в/с) (дата)

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;

    final preDate = match.group(1);
    final postDate = match.group(3);

    if (preDate == null && postDate == null) {
      return false;
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
      return false;
    }

    final builder = AbstractDate.builder();
    builder.time = Duration(hours: hourStart);
    builder.fix(FixPeriod.timeUncertain);

    final int start;
    if (preDate != null) {
      start = tokens[match.start + 1].start;
    } else {
      start = tokens[match.start].start;
    }

    final int end;
    if (postDate != null) {
      end = tokens[match.end - 2].end;
    } else {
      end = tokens[match.end - 1].end;
    }

    final List<Token> newTokens;
    if (hourStart == hourEnd) {
      newTokens = [
        if (preDate != null) tokens[match.start],
        DateToken(
          start: start,
          end: end,
          date: builder.build(),
        ),
        if (postDate != null) tokens[match.end - 1],
      ];
    } else {
      final spanBuilder = AbstractDate.builder(time: Duration(hours: hourEnd));
      spanBuilder.fix(FixPeriod.timeUncertain);
      newTokens = [
        if (preDate != null) tokens[match.start],
        DateToken(start: start, end: end, date: builder.build()),
        TokenParsers.timeTo.toMaybeDateToken(start, end),
        DateToken(start: start, end: end, date: spanBuilder.build()),
        if (postDate != null) tokens[match.end - 1],
      ];
    }

    // todo: better way to replace
    tokens.replaceRange(
      match.start,
      match.end,
      newTokens,
    );

    return true;
  }
}
