import '../../hors.dart';
import '../data.dart';
import 'recognizer.dart';

class YearRecognizer extends Recognizer {
  const YearRecognizer();

  @override
  RegExp get regexp => RegExp(r'(1)Y?|(0)Y'); // [в] 15 году/2017 (году)

  @override
  List<Token>? parser(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
    final yearStr = tokens.first.text;
    int? year = int.tryParse(yearStr);

    if (year == null) return null;

    if (year >= 70 && year < 100) {
      year += 1900;
    } else if (year < 1000) {
      year += 2000;
    }

    final builder = AbstractDate.builder(date: DateTime(year, 1, 1));
    builder.fix(FixPeriod.year);

    return [
      DateToken(
        start: tokens.first.start,
        end: tokens.last.end,
        date: builder.build(),
      )
    ];
  }
}