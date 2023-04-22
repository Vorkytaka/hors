import 'package:meta/meta.dart';

import 'data.dart';
import 'domain.dart';
import 'recognizer/recognizer.dart';
import 'token/token_parser.dart';

/// todo: docs
@experimental
class Hors {
  /// todo: docs
  @experimental
  const Hors({
    required this.recognizers,
    required this.tokenParsers,
  })  : assert(recognizers.length > 0),
        assert(tokenParsers.length > 0);

  final List<Recognizer> recognizers;
  final List<TokenParser> tokenParsers;

  static final Pattern _extraSymbols = RegExp('[^0-9а-яё-]');
  static final Pattern _allowSymbols = RegExp('[а-яА-ЯёЁa-zA-Z0-9-]+');

  /// Parse input [text] for some dates.
  /// todo: docs
  @experimental
  HorsResult parse(
    String text, [
    DateTime? fromDatetime,
    int closestSteps = 4,
  ]) {
    ParsingData data = ParsingData(
      sourceText: text,
      tokens: _allowSymbols
          .allMatches(text.toLowerCase())
          .map(_matchToTextToken)
          .map(_tokenToMaybeDate)
          .toList(),
    );

    // Remove extra zeros, because we don't need them
    _fixZeros(data);

    // If we don't have date, then use current datetime
    fromDatetime ??= DateTime.now();

    for (final recognizer in recognizers) {
      recognizer.recognize(data, fromDatetime);
    }

    final RegExp startPeriodsPattern = RegExp(r'(?<!(t))(@)(?=((N?[fo]?)(@)))');
    final RegExp endPeriodsPattern = RegExp(r'(?<=(t))(@)(?=((N?[fot]?)(@)))');

    parsing(
      data,
      startPeriodsPattern,
      collapseDates,
    );

    parsing(
      data,
      endPeriodsPattern,
      collapseDates,
    );

    parsing(
      data,
      endPeriodsPattern,
      takeFromA,
    );

    parsing(
      data,
      startPeriodsPattern,
      takeFromA,
    );

    if (closestSteps >= 1) {
      // Case, when two date tokens is related, but stay far from each other
      // We need to collapse them logically, but not as a string
      // Example: `Завтра пойду гулять в 11 часов`
      final regexp = RegExp('(@)[^@t]{1,$closestSteps}(?=(@))');
      int lastGroup = 0;
      parsing(
        data,
        regexp,
        (match, data) => collapseClosest(match, data, lastGroup++),
      );
    }

    final tokens = getFinalTokens(fromDatetime, data);
    final textWithoutTokens = _textWithoutTokens(text, tokens);

    return HorsResult(
      sourceText: text,
      tokens: tokens,
      textWithoutTokens: textWithoutTokens,
    );
  }

  /// Transform each match to [TextToken].
  static Token _matchToTextToken(Match match) {
    return TextToken(
      text: match.group(0)!,
      start: match.start,
      end: match.end,
    );
  }

  /// Try to transform each [Token] to [MaybeDateToken].
  /// If this is not possible, then just return original [token].
  Token _tokenToMaybeDate(Token token) {
    final symbol = _wordToSymbol(token.text);
    if (symbol != null) {
      return token.toMaybeDateToken(symbol);
    }
    return token;
  }

  String? _wordToSymbol(String word) {
    final rawWord = word.replaceAll(_extraSymbols, '').toLowerCase().trim();

    for (final token in tokenParsers) {
      final symbol = token.parse(rawWord);
      if (symbol != null) return symbol;
    }

    return null;
  }

  /// Remove extra zeros from data and update pattern.
  /// TODO: Research. Maybe we don't need it?
  static void _fixZeros(ParsingData data) {
    for (int i = data.tokens.length - 1; i > 0; i--) {
      if (data.tokens[i - 1].text == '0' &&
          int.tryParse(data.tokens[i].text) != null) {
        data.tokens.removeAt(i - 1);
      }
    }

    data.updatePattern();
  }

  /// Return text without tokens start with upper char.
  /// TODO: Optimize and tests for this function.
  static String _textWithoutTokens(
    String text,
    List<DateTimeToken> tokens,
  ) {
    final List<IntRange> ranges = tokens
        .map((e) => e.ranges)
        .expand((element) => element)
        .toList(growable: false);

    for (int i = ranges.length - 1; i >= 0; i--) {
      final range = ranges[i];

      text = text.substring(0, range.start) +
          (range.end < text.length ? text.substring(range.end) : '');
    }

    // Remove extra spaces
    text = text.trim().replaceAll(RegExp(r'\s{2,}'), ' ');

    // If text is not empty, then start it with upper char
    if (text.isNotEmpty) {
      text = text.substring(0, 1).toUpperCase() + text.substring(1);
    }

    return text;
  }
}

/// TODO: docs
@experimental
@immutable
class HorsResult {
  final String sourceText;
  final List<DateTimeToken> tokens;
  final String textWithoutTokens;

  /// TODO: docs
  const HorsResult({
    required this.sourceText,
    required this.tokens,
    required this.textWithoutTokens,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HorsResult &&
          runtimeType == other.runtimeType &&
          sourceText == other.sourceText &&
          tokens == other.tokens &&
          textWithoutTokens == other.textWithoutTokens;

  @override
  int get hashCode => Object.hash(sourceText, tokens, textWithoutTokens);

  @override
  String toString() => 'HorsResult{source: $sourceText, tokens: $tokens}';
}

enum DateTimeTokenType {
  fixed,
  period,
  spanForward,
  spanBackward,
}

/// TODO: Docs
@immutable
@experimental
class DateTimeToken {
  final DateTime date;
  final DateTime? dateTo;
  final Duration? span;
  final bool hasTime;
  final List<IntRange> ranges;
  final DateTimeTokenType type;

  const DateTimeToken({
    required this.date,
    required this.dateTo,
    required this.span,
    required this.hasTime,
    required this.ranges,
    required this.type,
  });

  @override
  String toString() => 'DateTimeToken($type, $date)';

  @override
  bool operator ==(Object other) =>
      other is DateTimeToken &&
      runtimeType == other.runtimeType &&
      date == other.date &&
      dateTo == other.dateTo &&
      span == other.span &&
      hasTime == other.hasTime &&
      ranges == other.ranges &&
      type == other.type;

  @override
  int get hashCode => Object.hash(date, dateTo, span, hasTime, ranges, type);
}

/// TODO: Docs
@immutable
class IntRange {
  final int start;
  final int end;

  const IntRange({
    required this.start,
    required this.end,
  });

  @override
  bool operator ==(Object other) =>
      other is IntRange &&
      runtimeType == other.runtimeType &&
      start == other.start &&
      end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'IntRange($start, $end)';
}
