import 'package:hors/hors.dart';
import 'package:hors/src/data.dart';
import 'package:hors/src/domain.dart';
import 'package:hors/src/recognizer/numbers_in_words_recognizer.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final recognizer = NumbersInWordsRecognizer();

  test(
    'Simple number',
    () {
      final data = 'В двадцать втором году гулять'.toParsingData;
      recognizer.recognize(data, DateTime(1994));
      expect(data.tokens[1].symbol, '0');
      expect(data.tokens[1].text, '22');
    },
  );

  test(
    'Hours with minutes',
    () {
      final data = 'В тринадцать тридцать пять что-то там'.toParsingData;
      recognizer.recognize(data, DateTime(1994));
      expect(data.tokens[1].symbol, '0');
      expect(data.tokens[1].text, '13');
      expect(data.tokens[2].symbol, '0');
      expect(data.tokens[2].text, '35');
    },
  );

  test(
    'Complex',
    () {
      final data =
          'В две тысячи двадцать четвертом году, двадцатого апреля, в двадцать три пятьдесят восемь я повзрослею'
              .toParsingData;
      recognizer.recognize(data, DateTime(1994));
      expect(data.tokens[1].symbol, '1');
      expect(data.tokens[1].text, '2024');
      expect(data.tokens[3].symbol, '0');
      expect(data.tokens[3].text, '20');
      expect(data.tokens[6].symbol, '0');
      expect(data.tokens[6].text, '23');
      expect(data.tokens[7].symbol, '0');
      expect(data.tokens[7].text, '58');
    },
  );
}

extension on String {
  ParsingData get toParsingData => ParsingData(
        sourceText: this,
        tokens: RegExp(r'[а-яА-ЯёЁa-zA-Z0-9-]+')
            .allMatches(toLowerCase())
            .map(matchToTextToken)
            .map((token) {
          for (final parser in TokenParsers.numbersInWords) {
            final symbol = parser.parse(token.text);
            if (symbol != null) {
              return MaybeDateToken(
                text: token.text,
                start: token.start,
                end: token.end,
                symbol: symbol,
              );
            }
          }
          return token;
        }).toList(),
      );
}
