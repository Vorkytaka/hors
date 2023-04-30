import '../../hors.dart';
import '../data.dart';

/// Recognizer that trying to parse all numbers that written in words
/// and replace them with integers value.
class NumbersInDatesRecognizer extends Recognizer {
  const NumbersInDatesRecognizer();

  @override
  RegExp get regexp => RegExp(r'x+');

  // TODO: Several numbers?
  // For now, this recognizer can parse one and only one number per parse.
  // But what if we need to parse several?
  // Looks like we can, instead of return false on some case, create new integer
  // And replace tokens with list of new
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
    for (int i = 0; i < length; i++) {
      final index = match.start + i;
      final token = tokens[index];

      final parser = TokenParsers.numbersInWords
          .firstWhere((parser) => parser.parse(token.text) != null);

      if (parser.isMultiplier) {
        if (globalLevel != null && parser.level >= globalLevel) {
          return false;
        }

        globalLevel = parser.level;
        globalValue +=
            localValue == 0 ? parser.value : parser.value * localValue;

        localLevel = null;
        localValue = 0;
      } else {
        if (localLevel != null && parser.level >= localLevel) {
          return false;
        }

        localLevel = parser.level;
        localValue += parser.value;
      }
    }

    final value = globalValue + localValue;

    if (value > 9999) {
      return false;
    }

    final String symbol;
    if (value < 1900) {
      symbol = '0';
    } else {
      symbol = '1';
    }

    final start = tokens[match.start].start;
    final end = tokens[match.end - 1].end;

    tokens.replaceRange(
      match.start,
      match.end,
      [
        MaybeDateToken(
          text: value.toString(),
          start: start,
          end: end,
          symbol: symbol,
        ),
      ],
    );

    return true;
  }
}
