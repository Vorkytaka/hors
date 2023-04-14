import 'package:hors/src/data.dart';
import 'package:hors/src/recognizer/recognizer.dart';
import 'package:hors/src/token/token_parser.dart';
import 'package:hors/src/token/token_parsers.dart';

class HolidayRecognizer extends Recognizer {
  const HolidayRecognizer();

  @override
  RegExp get regexp => RegExp(r'W');

  @override
  List<Token>? parser(
    DateTime fromDatetime,
    Match match,
    List<Token> tokens,
  ) {
    final token = tokens.first;

    final symbol = TokenParsers.holiday.parse(
      token.text,
      ParserPluralOption.singular,
    );

    if (symbol != null) {
      return [TokenParsers.saturday.toMaybeDateToken(token.start, token.end)];
    } else {
      return [
        TokenParsers.saturday.toMaybeDateToken(token.start, token.end),
        TokenParsers.timeTo.toMaybeDateToken(token.start, token.end),
        TokenParsers.sunday.toMaybeDateToken(token.start, token.end),
      ];
    }
  }
}
