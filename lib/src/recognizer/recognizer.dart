import '../data.dart';
import '../domain.dart';
import 'dates_period_recognizer.dart';
import 'day_of_month_recognizer.dart';
import 'day_of_week_recognizer.dart';
import 'holiday_recognizer.dart';
import 'month_recognizer.dart';
import 'part_of_day_recognizer.dart';
import 'relative_date_recognizer.dart';
import 'relative_day_recognizer.dart';
import 'time_recognizer.dart';
import 'time_span_recognizer.dart';
import 'year_recognizer.dart';

/// TODO: Docs
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

  /// TODO: Docs
  RegExp get regexp;

  /// TODO: Docs
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  );

  /// TODO: Docs
  void recognize(ParsingData data, DateTime fromDatetime) => parsing(
        data,
        regexp,
        (match, tokens) => parser(fromDatetime, match, tokens),
      );
}
