import 'recognizer.dart';
import 'token/token.dart';

class Hors {
  const Hors({
    required this.recognizers,
    required this.tokens,
  }) : assert(tokens.length > 0);

  final List<Recognizer> recognizers;
  final List<Token> tokens;

  static final Pattern _extraSymbols = RegExp('[^0-9а-яё-]');
  static final Pattern _allowSymbols = RegExp('[^а-яА-ЯёЁa-zA-Z0-9-]+');

  void parse(String text, DateTime fromDatetime) {
    final words = text.split(_allowSymbols);
    final pattern = words.map((word) => wordToSymbol(word)).join();
    print(pattern);
  }

  String wordToSymbol(String word) {
    final rawWord = word.replaceAll(_extraSymbols, '').toLowerCase().trim();

    for (final token in tokens) {
      final symbol = token.parse(rawWord);
      if (symbol != null) return symbol;
    }

    return '_';
  }
}
