import 'package:hors/src/data.dart';
import 'package:hors/src/hors.dart';
import 'package:hors/src/recognizer/recognizer.dart';
import 'package:hors/src/token/token_parsers.dart';
import 'package:hors/src/utils.dart';

class DatesPeriodRecognizer extends Recognizer {
  const DatesPeriodRecognizer();

  @override
  RegExp get pattern => RegExp(r'f?(0)[ot]0([M#])'); // с 26 до 27 января/числа

  @override
  List<Token>? parse(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
    bool monthFixed = false;

    final monthToken = tokens
        .firstWhere((token) => token.symbol == 'M' || token.symbol == '#');
    int month = fromDatetime.month;
    for (final parser in TokenParsers.months) {
      final symbol = parser.parse(monthToken.text);
      if (symbol != null) {
        month = parser.order;
        monthFixed = true;
        break;
      }
    }

    int? dayIndex = tokens.indexWhere((token) => token.symbol == '0');
    final dayToken = tokens[dayIndex];
    int? day = int.tryParse(dayToken.text);
    if (day == null) return null;
    final validDay = getValidDayForMonth(fromDatetime.year, month, day);

    final dateBuilder = AbstractDate.builder();
    dateBuilder.date = DateTime(fromDatetime.year, month, validDay);
    dateBuilder.fix(FixPeriod.week);
    dateBuilder.fix(FixPeriod.day);
    if (monthFixed) dateBuilder.fix(FixPeriod.month);

    return [...tokens]..[dayIndex] = dayToken.toDateToken(dateBuilder.build());
  }
}
