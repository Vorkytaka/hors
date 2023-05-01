import '../../hors.dart';
import '../data.dart';

/// Recognizer that trying to parse all numbers that written in words
/// and replace them with integers value.
class NumbersInWordsRecognizer extends Recognizer {
  const NumbersInWordsRecognizer();

  @override
  RegExp get regexp => RegExp(r'z+');

  @override
  bool parser(
    DateTime fromDatetime,
    Match match,
    ParsingData data,
  ) {
    final tokens = data.tokens;
    final length = match.end - match.start;

    int? globalLevel;
    int globalValue = 0;
    int? localLevel;
    int localValue = 0;
    int start = 0;
    int end = 0;
    final newTokens = <Token>[];
    for (int i = 0; i < length; i++) {
      final index = match.start + i;
      final token = tokens[index];

      final parser = TokenParsers.numbersInWords
          .firstWhere((parser) => parser.parse(token.text) != null);

      final isNewNumber = (parser.isMultiplier &&
              globalLevel != null &&
              parser.level >= globalLevel) ||
          (!parser.isMultiplier &&
              localLevel != null &&
              parser.level >= localLevel);

      if (isNewNumber) {
        final value = globalValue + localValue;

        final String? symbol;
        if (value < 1900) {
          symbol = '0';
        } else if (value < 9999) {
          symbol = '1';
        } else {
          symbol = null;
        }

        final Token newToken;
        if (symbol != null) {
          newToken = MaybeDateToken(
            text: value.toString(),
            start: start,
            end: end,
            symbol: symbol,
          );
        } else {
          newToken = TextToken(
            text: data.sourceText.substring(start, end),
            start: start,
            end: end,
          );
        }

        newTokens.add(newToken);

        globalLevel = null;
        globalValue = 0;
        localLevel = null;
        localValue = 0;
        start = token.start;
      }

      if (parser.isMultiplier) {
        globalLevel = parser.level;
        globalValue +=
            localValue == 0 ? parser.value : parser.value * localValue;

        localLevel = null;
        localValue = 0;
      } else {
        localLevel = parser.level;
        localValue += parser.value;
      }

      end = token.end;
    }

    final value = globalValue + localValue;

    final String? symbol;
    if (value < 1900) {
      symbol = '0';
    } else if (value < 9999) {
      symbol = '1';
    } else {
      symbol = null;
    }

    final Token newToken;
    if (symbol != null) {
      newToken = MaybeDateToken(
        text: value.toString(),
        start: start,
        end: end,
        symbol: symbol,
      );
    } else {
      newToken = TextToken(
        text: data.sourceText.substring(start, end),
        start: start,
        end: end,
      );
    }

    newTokens.add(newToken);

    tokens.replaceRange(
      match.start,
      match.end,
      newTokens,
    );

    return true;
  }
}
