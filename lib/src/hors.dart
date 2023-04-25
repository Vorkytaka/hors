import 'package:meta/meta.dart';

import 'data.dart';
import 'domain.dart';
import 'recognizer/recognizer.dart';
import 'token/token_parser.dart';

/// A simple class to extract date and time from natural speech.
///
/// __Currently only works with russian language__
///
/// In many cases all you need to do it's initialize [Hors] with all parsers and recognizer.
/// ```
/// final hors = Hors(
///   recognizers: Recognizer.all,
///   tokenParsers: TokenParsers.all,
/// );
///
/// final result = hors.parse('Завтра состоится событие');
/// ```
@experimental
class Hors {
  /// Create a new instance of [Hors] with specific lists of recognizers and parsers.
  @experimental
  const Hors({
    required this.recognizers,
    required this.tokenParsers,
  })  : assert(recognizers.length > 0),
        assert(tokenParsers.length > 0);

  /// List of [Recognizer] that will be used in this instance of [Hors].
  final List<Recognizer> recognizers;

  /// List of [TokenParser] that will be used in this instance of [Hors].
  final List<TokenParser> tokenParsers;

  static final Pattern _extraSymbols = RegExp('[^0-9а-яё-]');
  static final Pattern _allowSymbols = RegExp('[а-яА-ЯёЁa-zA-Z0-9-]+');

  /// Parse input for possible dates.
  ///
  /// Optional [fromDatetime] the date relative to which the intervals are to be measured.
  /// If it's null, then `DateTime.now()` will be used.
  ///
  /// [closestSteps] the maximum number of words between two dates at which will try to combine
  /// these dates into one, if possible. Default to 4.
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
          .map(matchToTextToken)
          .map(_tokenToMaybeDate)
          .toList(),
    );

    // Remove extra zeros, because we don't need them
    fixZeros(data);

    // If we don't have date, then use current datetime
    fromDatetime ??= DateTime.now();

    for (final recognizer in recognizers) {
      recognizer.recognize(data, fromDatetime);
    }

    final RegExp startPeriodsPattern = RegExp(r'(?<!(t))(@)(?=((N?[fo]?)(@)))');
    final RegExp endPeriodsPattern = RegExp(r'(?<=(t))(@)(?=((N?[fot]?)(@)))');

    // Try to collapse standing side by side [DateToken] into single one.
    parsing(
      data,
      startPeriodsPattern,
      collapseDates,
    );

    // Try to collapse standing side by side [DateToken] into single one.
    parsing(
      data,
      endPeriodsPattern,
      collapseDates,
    );

    // Try to combine standing side by side [DateToken].
    parsing(
      data,
      endPeriodsPattern,
      fillAdjacentDates,
    );

    // Try to combine standing side by side [DateToken].
    parsing(
      data,
      startPeriodsPattern,
      fillAdjacentDates,
    );

    if (closestSteps >= 1) {
      // Case, when two date tokens is related, but stay far from each other
      // We need to collapse them logically, but not as a string
      //
      // Example: `Завтра пойду гулять в 11 часов`
      final regexp = RegExp('(@)[^@t]{1,$closestSteps}(?=(@))');

      // When we combine tokens like this, then we need to indicate them.
      // This is used for it and increment for each group.
      int lastGroup = 0;
      parsing(
        data,
        regexp,
        (match, data) => collapseOnDistance(match, data, lastGroup++),
      );
    }

    final tokens = getFinalTokens(fromDatetime, data);
    final List<IntRange> tokenRanges = tokens
        .map((e) => e.ranges)
        .expand((element) => element)
        .toList(growable: false);
    final ranges = combineIntRange(tokenRanges);
    final textWithoutTokens = generateTextWithoutTokens(text, ranges);

    return HorsResult(
      sourceText: text,
      tokens: tokens,
      textWithoutTokens: textWithoutTokens,
      ranges: ranges,
    );
  }

  /// Try to transform [Token] to [MaybeDateToken].
  /// If this is not possible, then just return original [token].
  Token _tokenToMaybeDate(Token token) {
    final symbol = _wordToSymbol(token.text);
    if (symbol != null) {
      return token.toMaybeDateToken(symbol);
    }
    return token;
  }

  /// Parse [word] and try to found symbol for that word.
  /// Return null if no symbol found.
  // TODO: Maybe should optimize this code with hashes.
  String? _wordToSymbol(String word) {
    final rawWord = word.replaceAll(_extraSymbols, '').toLowerCase().trim();

    for (final token in tokenParsers) {
      final symbol = token.parse(rawWord);
      if (symbol != null) return symbol;
    }

    return null;
  }
}

/// Result of parsing from [Hors.parse].
///
/// [sourceText] is just initial text, that was parsed.
/// [tokens] is collection of all parsed dates.
/// [textWithoutTokens] is initial text, but without date tokens, and also starts with capital letter.
@experimental
@immutable
class HorsResult {
  /// Initial text that was parsed.
  final String sourceText;

  /// List of [DateTimeToken] that was found in [sourceText].
  ///
  /// Can be empty.
  final List<DateTimeToken> tokens;

  /// Text without dates.
  final String textWithoutTokens;

  /// List of all ranges from [tokens] that combine together.
  ///
  /// Useful for cases, when you need to indicate all tokens in the [sourceText].
  final List<IntRange> ranges;

  /// Used for create hors results.
  const HorsResult({
    required this.sourceText,
    required this.tokens,
    required this.textWithoutTokens,
    required this.ranges,
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

/// Type of founded date token.
@experimental
enum DateTimeTokenType {
  /// Fixed date and (maybe) time.
  fixed,

  /// Period from [DateTimeToken.date] to [DateTimeToken.dateTo].
  ///
  /// [DateTimeToken.dateTo] is not null in this case.
  period,

  /// Span forward.
  ///
  /// [DateTimeToken.date] is show datetime of event.
  /// [DateTimeToken.span] is not null and show duration from current datetime to event.
  spanForward,

  /// Span backward.
  ///
  /// [DateTimeToken.date] is show datetime of event.
  /// [DateTimeToken.span] is not null and show duration from current datetime to event.
  spanBackward,
}

/// Data class with everything over one parsed date.
@immutable
@experimental
class DateTimeToken {
  /// Main datetime field that was parsed.
  ///
  /// When [type] is [DateTimeTokenType.fixed], then this field is just datetime of parsed string.
  /// When [type] is [DateTimeTokenType.period], then this field is start point in time of the period.
  /// When [type] is either [DateTimeTokenType.spanForward] or [DateTimeTokenType.spanBackward], then this field is datetime of parsed string.
  ///
  /// If field [hasTime] is true, then time in this field specify exactly time.
  /// Otherwise time fields can be ignored.
  ///
  /// Every other field in this class it's works around this one.
  final DateTime date;

  /// Datetime that indicates end of period.
  ///
  /// Not null in case, when [type] of this token is [DateTimeTokenType.period].
  /// In any other case it's null.
  ///
  /// If field [hasTime] is true, then time in this field specify exactly time.
  /// Otherwise time fields can be ignored.
  final DateTime? dateTo;

  /// Duration of span, that was used for [date].
  ///
  /// Not null in case, when [type] either is [DateTimeTokenType.spanForward] or [DateTimeTokenType.spanBackward].
  /// In any other case it's null.
  final Duration? span;

  /// Indicate if in any [date] or/and [dateTo] is specify time.
  final bool hasTime;

  /// Ranges of this [DateTimeToken] in input source text.
  final List<IntRange> ranges;

  /// Type of this token.
  ///
  /// See [DateTimeTokenType] for more info.
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
  String toString() {
    final sb = StringBuffer('DateTimeToken, ');

    final typeName = type.toString().split('.').last;
    sb.write(typeName);
    sb.write(':\n\t');

    switch (type) {
      case DateTimeTokenType.fixed:
        sb.write(date);
        break;
      case DateTimeTokenType.period:
        sb.write('From:\t');
        sb.write(date);
        sb.write('\n\tTo:\t\t');
        sb.write(dateTo);
        break;
      case DateTimeTokenType.spanForward:
      case DateTimeTokenType.spanBackward:
        sb.write('Date:\t');
        sb.write(date);
        sb.write('\n\tSpan:\t');
        sb.write(span);
        break;
    }
    return sb.toString();
  }

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

/// Range of intergers.
@immutable
class IntRange {
  final int start;
  final int end;

  const IntRange({
    required this.start,
    required this.end,
  })  : assert(start >= 0),
        assert(end >= start);

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
