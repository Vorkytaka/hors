import 'dart:math';

import 'package:hors/src/data.dart';

import 'recognizer/recognizer.dart';
import 'token/token_parser.dart';

class Hors {
  const Hors({
    required this.recognizers,
    required this.tokenParsers,
  }) : assert(tokenParsers.length > 0);

  final List<Recognizer> recognizers;
  final List<TokenParser> tokenParsers;

  static final Pattern _extraSymbols = RegExp('[^0-9а-яё-]');
  static final Pattern _allowSymbols = RegExp('[а-яА-ЯёЁa-zA-Z0-9-]+');

  void x(String text, DateTime fromDatetime) {
    ParsingData data = ParsingData(
      sourceText: text,
      tokens: _allowSymbols
          .allMatches(text.toLowerCase())
          .map(_matchToTextToken)
          .map(_tokenToMaybeDate)
          .toList(growable: false),
    );

    for (final recognizer in recognizers) {
      data = recognizer.recognize(data, fromDatetime);
    }

    print(data);
  }

  static Token _matchToTextToken(Match match) {
    return TextToken(
      text: match.group(0)!,
      start: match.start,
      end: match.end,
    );
  }

  Token _tokenToMaybeDate(Token token) {
    final symbol = wordToSymbol(token.text);
    if (symbol != null) {
      return token.toMaybeDateToken(symbol);
    }
    return token;
  }

  // static List<Token> getTokens(String text) {
  //   text = text.toLowerCase();
  //   _allowSymbols.allMatches(text);
  // }

  String? wordToSymbol(String word) {
    final rawWord = word.replaceAll(_extraSymbols, '').toLowerCase().trim();

    for (final token in tokenParsers) {
      final symbol = token.parse(rawWord);
      if (symbol != null) return symbol;
    }

    return null;
  }
}

enum FixPeriod {
  none(0),
  time(1),
  timeUncertain(2),
  day(4),
  week(8),
  month(16),
  year(32);

  final int bit;

  const FixPeriod(this.bit);
}

class AbstractDateBuilder {
  DateTime? date;
  Duration? time;
  Duration? span;
  int fixes = 0;
  bool fixDayOfWeek = false;

  // todo: enum?
  int? spanDirection;

  AbstractDateBuilder._({
    this.date,
    this.time,
    this.span,
    this.fixes = 0,
    this.fixDayOfWeek = false,
    this.spanDirection,
  });

  AbstractDate build() {
    return AbstractDate._(
      date: date,
      time: time,
      span: span,
      fixes: fixes,
      fixDayOfWeek: fixDayOfWeek,
      spanDirection: spanDirection,
    );
  }

  void fix(FixPeriod fix) {
    fixes = fixes | fix.bit;
  }

  void fixDownTo(FixPeriod period) {
    for (final p in FixPeriod.values) {
      if (p.index < period.index) {
        continue;
      }

      fix(p);
    }
  }

  bool isFixed(FixPeriod period) {
    return (fixes & period.bit) > 0;
  }

  int get maxPeriod {
    int maxVal = 0;
    for (final period in FixPeriod.values) {
      if (period.index > maxVal) {
        maxVal = period.index;
      }
    }

    return log(maxVal).toInt();
  }
}

class AbstractDate {
  final DateTime? date;
  final Duration? time;
  final Duration? span;
  final int fixes;
  final bool fixDayOfWeek;
  final int? spanDirection;

  AbstractDate._({
    this.date,
    this.time,
    this.span,
    this.fixes = 0,
    this.fixDayOfWeek = false,
    this.spanDirection,
  });

  static AbstractDateBuilder builder({
    DateTime? date,
    Duration? time,
    Duration? span,
    int fixes = 0,
    bool fixDayOfWeek = false,
    int? spanDirection,
  }) =>
      AbstractDateBuilder._(
        date: date,
        time: time,
        span: span,
        fixes: fixes,
        fixDayOfWeek: fixDayOfWeek,
        spanDirection: spanDirection,
      );

  AbstractDate fix(List<FixPeriod> fixes) {
    int newFixes = this.fixes;
    for (final fix in fixes) {
      newFixes = newFixes | fix.index;
    }
    return AbstractDate._(
      date: date,
      time: time,
      span: span,
      fixes: newFixes,
    );
  }
}

class ParseResult {
  final String output;
  final List<AbstractDate> tokens;

  const ParseResult({
    required this.output,
  }) : tokens = const [];

  const ParseResult._({
    required this.output,
    required this.tokens,
  });

  ParseResult copyWith({
    required String output,
    required List<AbstractDate> tokens,
  }) {
    return ParseResult._(
      output: output,
      tokens: tokens,
    );
  }
}
