import '../data.dart';
import '../token/token_parser.dart';
import '../token/token_parsers.dart';
import 'recognizer.dart';

class HolidayRecognizer extends Recognizer {
  const HolidayRecognizer();

  @override
  RegExp get regexp => RegExp(r'W');

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;
    final token = tokens[match.start];

    final symbol = TokenParsers.holiday.parse(
      token.text,
      ParserPluralOption.singular,
    );

    final List<Token> newTokens;
    if (symbol != null) {
      newTokens = [
        TokenParsers.saturday.toMaybeDateToken(token.start, token.end),
      ];
    } else {
      newTokens = [
        TokenParsers.saturday.toMaybeDateToken(token.start, token.end),
        TokenParsers.timeTo.toMaybeDateToken(token.start, token.end),
        TokenParsers.sunday.toMaybeDateToken(token.start, token.end),
      ];
    }

    tokens.replaceRange(
      match.start,
      match.end,
      newTokens,
    );

    return true;
  }
}
