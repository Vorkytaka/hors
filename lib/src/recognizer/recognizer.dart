import 'package:hors/src/recognizer/part_of_day_recognizer.dart';
import 'package:hors/src/recognizer/relative_date_recognizer.dart';
import 'package:hors/src/recognizer/time_recognizer.dart';

import '../data.dart';
import '../utils.dart';
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

  RegExp get pattern;

  List<Token>? parse(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  );

  ParsingData recognize(ParsingData data, DateTime fromDatetime) {
    final newTokens = matchAll(
      pattern,
      data.tokens,
      (match, tokens) => parse(fromDatetime, match, tokens),
    );

    if (newTokens == null) {
      return data;
    }

    return ParsingData(
      sourceText: data.sourceText,
      tokens: newTokens,
    );
  }
}

List<Token>? matchAll(
  RegExp regexp,
  List<Token> tokens,
  List<Token>? Function(Match match, List<Token> tokens) parser,
) {
  final pattern = tokens.toPattern;
  final matches = regexp.allMatches(pattern).iterator;

  if (!matches.moveNext()) {
    return null;
  }

  final List<Token> newTokens = [];
  int lastStart = 0;
  do {
    Match match = matches.current;
    newTokens.addAll(tokens.sublist(lastStart, match.start));

    final subtokens = tokens.sublist(match.start, match.end);
    final parsed = parser(match, subtokens);
    if (parsed != null) {
      newTokens.addAll(parsed);
    } else {
      newTokens.addAll(subtokens);
    }
    lastStart = match.end;
  } while (lastStart < pattern.length && matches.moveNext());

  if (lastStart < pattern.length) {
    newTokens.addAll(tokens.sublist(lastStart));
  }

  return newTokens;
}
