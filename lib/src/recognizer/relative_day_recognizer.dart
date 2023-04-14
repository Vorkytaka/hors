import '../data.dart';
import '../hors.dart';
import 'recognizer.dart';

class RelativeDayRecognizer extends Recognizer {
  const RelativeDayRecognizer();

  @override
  RegExp get regexp => RegExp(r'[2-6]');

  @override
  List<Token>? parser(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
    final token = tokens.first;
    int? relativeDay = int.tryParse(token.symbol);
    if (relativeDay == null) return null;
    relativeDay -= 4;
    final builder = AbstractDate.builder(
      date: fromDatetime.add(Duration(days: relativeDay)),
    );
    builder.fixDownTo(FixPeriod.day);
    return [token.toDateToken(builder.build())];
  }
}
