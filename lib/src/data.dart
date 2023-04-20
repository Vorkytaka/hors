import 'dart:math';

import 'package:hors/src/hors.dart';
import 'package:meta/meta.dart';

/// Mutable state for parsing data.
@internal
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

// DateToken toDateToken(AbstractDate date) {
//   return DateToken(
//     start: start,
//     end: end,
//     date: date,
//   );
// }
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
  DateTime? date;
  Duration? time;
  Duration? span;
  int fixes = 0;
  bool fixDayOfWeek = false;
  int spanDirection = 0;
  int? duplicateGroup;

  DateToken({
    required super.start,
    required super.end,
  }) : super(text: '{}');

  @override
  String get symbol => '@';

  @override
  String toString() => 'DateToken($start, $end)';

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

  FixPeriod get maxFixed {
    for (final period in FixPeriod.values) {
      if (isFixed(period)) {
        return period;
      }
    }

    return FixPeriod.none;
  }

  FixPeriod get minFixed {
    for (final period in FixPeriod.values.reversed) {
      if (isFixed(period)) {
        return period;
      }
    }

    return FixPeriod.none;
  }

  DateToken copy({int? start, int? end}) => DateToken(
        start: start ?? this.start,
        end: end ?? this.end,
      )
        ..date = date
        ..time = time
        ..span = span
        ..fixes = fixes
        ..fixDayOfWeek = fixDayOfWeek
        ..spanDirection = spanDirection
        ..duplicateGroup = duplicateGroup;
}
