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

    final RegExp startPeriodsPattern = RegExp(r'(?<!(t))(@)((N?[fo]?)(@))');
    final RegExp endPeriodsPattern = RegExp(r'(?<=(t))(@)((N?[fot]?)(@))');

    data = parsing(
      data,
      startPeriodsPattern,
      (match, tokens) => collapseDates(fromDatetime, match, tokens),
    );

    data = parsing(
      data,
      endPeriodsPattern,
      (match, tokens) => collapseDates(fromDatetime, match, tokens),
    );

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
  int fixes;
  bool fixDayOfWeek;
  int spanDirection;

  AbstractDateBuilder._({
    this.date,
    this.time,
    this.span,
    this.fixes = 0,
    this.fixDayOfWeek = false,
    this.spanDirection = 0,
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
        spanDirection: spanDirection ?? 0,
      );

  bool isFixed(FixPeriod period) {
    return (fixes & period.bit) > 0;
  }

  FixPeriod get minFixed {
    for (final period in FixPeriod.values.reversed) {
      if (isFixed(period)) {
        return period;
      }
    }

    return FixPeriod.none;
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

List<Token>? collapseDates(
  DateTime fromDatetime,
  Match match,
  List<Token> tokens,
) {
  final firstDateIndex = tokens.indexWhere((token) => token.symbol == '@');
  final secondDateIndex = tokens.indexWhere(
    (token) => token.symbol == '@',
    firstDateIndex + 1,
  );

  final firstDate = tokens[firstDateIndex] as DateToken;
  final secondDate = tokens[secondDateIndex] as DateToken;

  if (!canCollapse(firstDate.date, secondDate.date)) {
    return null;
  }

  final DateToken? newToken;
  if (firstDate.date.minFixed.index < secondDate.date.minFixed.index) {
    newToken = collapse(secondDate, firstDate, false);
  } else {
    newToken = collapse(firstDate, secondDate, false);
  }

  if (newToken == null) return null;
  return [newToken];
}

bool canCollapse(AbstractDate first, AbstractDate second) {
  if ((first.fixes & second.fixes) != 0) return false;
  return first.spanDirection != -(second.spanDirection ?? 0) ||
      first.spanDirection == 0;
}

// todo isLinked always false?
DateToken? collapse(DateToken baseToken, DateToken coverToken, bool isLinked) {
  final base = baseToken.date;
  final cover = coverToken.date;

  if (!canCollapse(base, cover)) {
    return null;
  }

  // todo: if base date is null?
  final builder = AbstractDate.builder(
    date: base.date,
  );

  if (base.spanDirection != 0 && cover.spanDirection != 0) {
    builder.spanDirection = base.spanDirection! + cover.spanDirection!;
  }

  if (!base.isFixed(FixPeriod.year) && cover.isFixed(FixPeriod.year)) {
    builder.date = DateTime(
      cover.date!.year,
      builder.date!.month,
      builder.date!.day,
    );
    builder.fix(FixPeriod.year);
  }

  if (!base.isFixed(FixPeriod.month) && cover.isFixed(FixPeriod.month)) {
    builder.date = DateTime(
      builder.date!.year,
      cover.date!.month,
      builder.date!.day,
    );
    builder.fix(FixPeriod.month);
  }

  if (!base.isFixed(FixPeriod.week) && cover.isFixed(FixPeriod.week)) {
    if (base.isFixed(FixPeriod.day)) {
      builder.date = takeDayOfWeekFrom(cover.date!, builder.date!);
      builder.fix(FixPeriod.week);
    } else if (!cover.isFixed(FixPeriod.day)) {
      builder.date = DateTime(
        builder.date!.year,
        builder.date!.month,
        cover.date!.day,
      );
      builder.fix(FixPeriod.week);
    }
  } else if (base.isFixed(FixPeriod.week) && cover.isFixed(FixPeriod.day)) {
    builder.date = takeDayOfWeekFrom(builder.date!, cover.date!);
    builder.fix(FixPeriod.week);
    builder.fix(FixPeriod.day);
  }

  if (!base.isFixed(FixPeriod.day) && cover.isFixed(FixPeriod.day)) {
    if (cover.fixDayOfWeek) {
      final current = DateTime(
        builder.date!.year,
        builder.date!.month,
        builder.isFixed(FixPeriod.week) ? builder.date!.day : 0,
      );
      builder.date = takeDayOfWeekFrom(
        current,
        cover.date!,
        !base.isFixed(FixPeriod.week),
      );
    } else {
      builder.date = DateTime(
        builder.date!.year,
        builder.date!.month,
        cover.date!.day,
      );
      builder.fix(FixPeriod.week);
      builder.fix(FixPeriod.day);
    }
  }

  bool timeGot = false;
  if (!base.isFixed(FixPeriod.time) && cover.isFixed(FixPeriod.time)) {
    builder.fix(FixPeriod.time);
    if (!base.isFixed(FixPeriod.timeUncertain)) {
      builder.time = cover.time;
    } else {
      if (base.time!.hours <= 12 && cover.time!.hours > 12) {
        if (!isLinked) {
          builder.time = builder.time! + Duration(hours: 12);
        }
      }
    }

    timeGot = true;
  }

  if (!base.isFixed(FixPeriod.timeUncertain) &&
      cover.isFixed(FixPeriod.timeUncertain)) {
    builder.fix(FixPeriod.timeUncertain);
    if (base.isFixed(FixPeriod.time)) {
      final offset = cover.time!.hours <= 12 && base.time!.hours > 12 ? 12 : 0;
      builder.time = Duration(
        hours: cover.time!.hours + offset,
        minutes: cover.time!.minutes,
      );
    } else {
      builder.time = cover.time;
      timeGot = true;
    }
  }

  if (timeGot && base.spanDirection != 0 && cover.spanDirection == 0) {
    if (base.spanDirection! > 0) {
      builder.span = base.time! + base.time!;
    } else {
      builder.span = base.time! - base.time!;
    }
  }

  return DateToken(
    start: min(baseToken.start, coverToken.start),
    end: max(baseToken.end, coverToken.end),
    date: builder.build(),
  );
}

// todo: Это практически прямая реализация TimeSpan из C#
// но кажется, что это не то, что по правде нужно в реализации
extension on Duration {
  int get hours =>
      (inSeconds ~/ Duration.secondsPerHour) % Duration.hoursPerDay;

  int get minutes =>
      (inSeconds ~/ Duration.secondsPerMinute) % Duration.minutesPerHour;
}

DateTime takeDayOfWeekFrom(
  DateTime current,
  DateTime from, [
  bool forward = false,
]) {
  int diff = from.weekday - current.weekday;
  if (forward && diff < 0) diff += 7;
  return current.add(Duration(days: diff));
}
