import 'package:meta/meta.dart';

import '../data.dart';
import '../domain.dart';
import 'dates_period_recognizer.dart';
import 'day_of_month_recognizer.dart';
import 'day_of_week_recognizer.dart';
import 'holiday_recognizer.dart';
import 'month_recognizer.dart';
import 'numbers_in_words_recognizer.dart';
import 'part_of_day_recognizer.dart';
import 'relative_date_recognizer.dart';
import 'relative_day_recognizer.dart';
import 'time_recognizer.dart';
import 'time_span_recognizer.dart';
import 'year_recognizer.dart';

/// Base class for recognize some date, time or spans from [ParsingData].
///
/// In many cases all you need to do is to use [Recognizer.all].
/// But you free to use any recognizers, or even create your own.
@experimental
abstract class Recognizer {
  const Recognizer();

  /// List of all default recognizer.
  static const List<Recognizer> all = [
    NumbersInWordsRecognizer(),
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

  /// Regular expression that used to found possible datetime in [ParsingData.pattern].
  RegExp get regexp;

  /// Method that get match of [regexp] from [ParsingData.pattern], and try to parse as real date data.
  ///
  /// Should return [true] if parsing was successful, [false] otherwise.
  /// This method is mutate [ParsingData], so, be careful with data.
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  );

  /// Main method that search and parse [ParsingData] for dates.
  ///
  /// When it's found some match, it goes through the matches in reverse order,
  /// and try to parse it with [parser].
  ///
  /// We use reverse order, because of mutable [ParsingData], so
  /// when we mutate data from the end, then matches at the start is not affected.
  void recognize(ParsingData data, DateTime fromDatetime) => parsing(
        data,
        regexp,
        (match, tokens) => parser(fromDatetime, match, tokens),
      );
}
