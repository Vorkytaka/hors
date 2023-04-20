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

  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  );

  void recognize(ParsingData data, DateTime fromDatetime) => parsing(
        data,
        regexp,
        (match, tokens) => parser(fromDatetime, match, tokens),
      );
}

void parsing(
  ParsingData data,
  RegExp regexp,
  bool Function(Match match, ParsingData data) parser,
) {
  // We use reversed data, because our data is mutable,
  // so, when we parse and mutate this data from the end
  // then it doesn't affect matches at a start.
  final matches =
      regexp.allMatches(data.pattern).toList(growable: false).reversed;

  if (matches.isEmpty) {
    return;
  }

  bool updatePattern = false;
  for (final match in matches) {
    updatePattern = parser(match, data) || updatePattern;
  }

  if (updatePattern) {
    data.updatePattern();
  }
}
