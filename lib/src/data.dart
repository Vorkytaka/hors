import 'package:hors/src/hors.dart';

class ParsingData {
  final String sourceText;
  final List<Token> tokens;
  String _pattern;

  ParsingData({
    required this.sourceText,
    required this.tokens,
  }) : _pattern = tokens.map((t) => t.symbol).join();

  String get pattern => _pattern;

  void updatePattern() => _pattern = tokens.map((t) => t.symbol).join();
}

/// For now, tokens have their own lifecycle.
/// Everything starts with [TextToken].
/// After that, token can be transform for [MaybeDateToken].
/// Then, it can be transform to the [DateToken].
abstract class Token {
  /// Text of this token
  final String text;

  /// Start of this token [text] in source text
  final int start;

  /// End of this token [text] in source text
  final int end;

  const Token({
    required this.text,
    required this.start,
    required this.end,
  });

  String get symbol;

  Token toMaybeDateToken(String symbol) {
    assert(symbol.length == 1);
    return MaybeDateToken(
      text: text,
      start: start,
      end: end,
      symbol: symbol,
    );
  }

  DateToken toDateToken(AbstractDate date) {
    return DateToken(
      start: start,
      end: end,
      date: date,
    );
  }
}

class TextToken extends Token {
  const TextToken({
    required super.text,
    required super.start,
    required super.end,
  });

  @override
  String get symbol => '_';

  @override
  String toString() => 'TextToken($text, $start, $end)';
}

class MaybeDateToken extends Token {
  const MaybeDateToken({
    required super.text,
    required super.start,
    required super.end,
    required this.symbol,
  });

  @override
  final String symbol;

  @override
  String toString() => 'MaybeDateToken($text, $start, $end, $symbol)';
}

class DateToken extends Token {
  final AbstractDate date;

  const DateToken({
    required super.start,
    required super.end,
    required this.date,
  }) : super(text: '{}');

  @override
  String get symbol => '@';

  @override
  String toString() => 'DateToken($start, $end, ${date.date})';
}
