import '../../hors.dart';
import '../data.dart';

class YearRecognizer extends Recognizer {
  const YearRecognizer();

  @override
  RegExp get regexp => RegExp(r'(1)Y?|(0)Y'); // [в] 15 году/2017 (году)

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;

    final yearStr = tokens[match.start].text;
    int? year = int.tryParse(yearStr);

    if (year == null) return false;

    if (year >= 70 && year < 100) {
      year += 1900;
    } else if (year < 1000) {
      year += 2000;
    }

    final builder = AbstractDate.builder(date: DateTime(year, 1, 1));
    builder.fix(FixPeriod.year);

    tokens.replaceRange(
      match.start,
      match.end,
      [
        DateToken(
          start: tokens[match.start].start,
          end: tokens[match.end - 1].end,
          date: builder.build(),
        )
      ],
    );

    return true;
  }
}
