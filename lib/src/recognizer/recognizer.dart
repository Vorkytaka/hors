import 'package:hors/src/recognizer/part_of_day_recognizer.dart';
import 'package:hors/src/recognizer/relative_date_recognizer.dart';
import 'package:hors/src/recognizer/time_recognizer.dart';

import '../data.dart';
import 'dates_period_recognizer.dart';
import 'day_of_month_recognizer.dart';
import 'day_of_week_recognizer.dart';
import 'holiday_recognizer.dart';
import 'month_recognizer.dart';
import 'relative_day_recognizer.dart';
import 'time_span_recognizer.dart';
import 'year_recognizer.dart';

abstract class Recognizer {
  const Recognizer();

  static const List<Recognizer> all = [
    HolidayRecognizer(),
    DatesPeriodRecognizer(),
    DayOfMonthRecognizer(),
    MonthRecognizer(),
    RelativeDayRecognizer(),
    TimeSpanRecognizer(),
    YearRecognizer(),
    RelativeDateRecognizer(),
    DayOfWeekRecognizer(),
    TimeRecognizer(),
    PartOfDayRecognizer(),
  ];

  RegExp get regexp;

  List<Token>? parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  );

  ParsingData recognize(ParsingData data, DateTime fromDatetime) => parsing(
        data,
        regexp,
        (match, tokens) => parser(fromDatetime, match, tokens),
      );
}

ParsingData parsing(
  ParsingData data,
  RegExp regexp,
  List<Token>? Function(Match match, ParsingData data) parser,
) {
  final newTokens = matchAll(
    regexp,
    data,
    parser,
  );

  if (newTokens == null) {
    return data;
  }

  return ParsingData(
    sourceText: data.sourceText,
    tokens: newTokens,
  );
}

// todo: reverse?
List<Token>? matchAll(
  RegExp regexp,
  ParsingData data,
  List<Token>? Function(Match match, ParsingData data) parser,
) {
  final tokens = data.tokens;
  final pattern = data.pattern;
  final matches = regexp.allMatches(pattern).iterator;

  if (!matches.moveNext()) {
    return null;
  }

  final List<Token> newTokens = [];
  int lastStart = 0;
  do {
    Match match = matches.current;
    newTokens.addAll(tokens.sublist(lastStart, match.start));

    final parsed = parser(match, data);
    if (parsed != null) {
      newTokens.addAll(parsed);
    } else {
      newTokens.addAll(tokens.sublist(match.start, match.end));
    }
    lastStart = match.end;
  } while (lastStart < pattern.length && matches.moveNext());

  if (lastStart < pattern.length) {
    newTokens.addAll(tokens.sublist(lastStart));
  }

  return newTokens;
}
