import '../data.dart';
import '../hors.dart';
import 'recognizer.dart';

class RelativeDayRecognizer extends Recognizer {
  const RelativeDayRecognizer();

  @override
  RegExp get regexp => RegExp(r'[2-6]');

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;
    final token = tokens[match.start];
    int? relativeDay = int.tryParse(token.symbol);
    if (relativeDay == null) return false;
    relativeDay -= 4;
    final dateToken = DateToken(
      start: token.start,
      end: token.end,
    );
    dateToken.date = fromDatetime.add(Duration(days: relativeDay));
    dateToken.fixDownTo(FixPeriod.day);
    tokens[match.start] = dateToken;
    return true;
  }
}
