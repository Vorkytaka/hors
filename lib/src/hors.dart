import 'dart:math';

import 'package:hors/src/data.dart';
import 'package:hors/src/utils.dart';
import 'package:meta/meta.dart';

import 'recognizer/recognizer.dart';
import 'token/token_parser.dart';

@experimental
class Hors {
  @experimental
  const Hors({
    required this.recognizers,
    required this.tokenParsers,
  }) : assert(tokenParsers.length > 0);

  final List<Recognizer> recognizers;
  final List<TokenParser> tokenParsers;

  static final Pattern _extraSymbols = RegExp('[^0-9а-яё-]');
  static final Pattern _allowSymbols = RegExp('[а-яА-ЯёЁa-zA-Z0-9-]+');

  @experimental
  HorsResult parse(String text, DateTime fromDatetime, [int closestSteps = 4]) {
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
      (match, data) => collapseDates(fromDatetime, match, data),
    );

    data = parsing(
      data,
      endPeriodsPattern,
      (match, data) => collapseDates(fromDatetime, match, data),
    );

    parsing2(
      data,
      RegExp(r'(?<=(t))(@)(?=((N?[fot]?)(@)))'),
      takeFromA,
      true,
    );

    parsing2(
      data,
      RegExp(r'(?<!(t))(@)(?=((N?[fo]?)(@)))'),
      takeFromA,
      true,
    );

    if (closestSteps > 1) {
      final regexp = RegExp('(@)[^@t]{1,$closestSteps}(?=(@))');
      int lastGroup = 0;
      parsing2(
        data,
        regexp,
        (match, data) => collapseClosest(match, data, lastGroup++),
        true,
      );
    }

    final tokens = getFinalTokens(fromDatetime, data);

    return HorsResult(
      source: text,
      tokens: tokens,
    );
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

@experimental
@immutable
class HorsResult {
  final String source;
  final List<DateTimeToken> tokens;

  const HorsResult({
    required this.source,
    required this.tokens,
  });

  // todo: better algo + results
  String get textWithoutDates {
    String str = source;
    for (final token in tokens.reversed) {
      str = str.replaceRange(token.start, token.end, '');
    }
    return str.trim();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HorsResult &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          tokens == other.tokens;

  @override
  int get hashCode => Object.hash(source, tokens);

  @override
  String toString() => 'HorsResult{source: $source, tokens: $tokens}';

// todo: string without tokens
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

  AbstractDateBuilder.fromDate(AbstractDate date)
      : date = date.date,
        time = date.time,
        span = date.span,
        fixes = date.fixes,
        fixDayOfWeek = date.fixDayOfWeek,
        spanDirection = date.spanDirection;

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

  FixPeriod get maxFixed {
    for (final period in FixPeriod.values) {
      if (isFixed(period)) {
        return period;
      }
    }

    return FixPeriod.none;
  }
}

class AbstractDate {
  final DateTime? date;
  final Duration? time;
  final Duration? span;
  final int fixes;
  final bool fixDayOfWeek;
  final int spanDirection;
  final int? duplicateGroup;

  AbstractDate._({
    this.date,
    this.time,
    this.span,
    this.fixes = 0,
    this.fixDayOfWeek = false,
    this.spanDirection = 0,
    this.duplicateGroup,
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

  FixPeriod get maxFixed {
    for (final period in FixPeriod.values) {
      if (isFixed(period)) {
        return period;
      }
    }

    return FixPeriod.none;
  }

  AbstractDate withDuplicateGroup(int group) {
    return AbstractDate._(
      date: date,
      time: time,
      span: span,
      fixes: fixes,
      fixDayOfWeek: fixDayOfWeek,
      spanDirection: spanDirection,
      duplicateGroup: group,
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

List<Token>? collapseDates(
  DateTime fromDatetime,
  Match match,
  ParsingData data,
) {
  final tokens = data.tokens;

  final firstDateIndex = tokens.indexWhere(
    (token) => token.symbol == '@',
    match.start,
  );
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
  return first.spanDirection != -second.spanDirection ||
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
  final builder = AbstractDateBuilder.fromDate(base);

  if (base.spanDirection != 0 && cover.spanDirection != 0) {
    builder.spanDirection = base.spanDirection + cover.spanDirection;
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
    }
    builder.fix(FixPeriod.week);
    builder.fix(FixPeriod.day);
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
    if (base.spanDirection > 0) {
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

// todo
void takeFromA(
  Match match,
  ParsingData data,
) {
  final tokens = data.tokens;

  final firstDateIndex = tokens.indexWhere(
    (token) => token.symbol == '@',
    match.start,
  );
  final secondDateIndex = tokens.indexWhere(
    (token) => token.symbol == '@',
    firstDateIndex + 1,
  );

  final firstToken = tokens[firstDateIndex] as DateToken;
  final secondToken = tokens[secondDateIndex] as DateToken;

  final newTokens = takeFromAdjacent(firstToken, secondToken, false);
  final newFirstToken = newTokens[0];
  final newSecondToken = newTokens[1];

  tokens
    ..[firstDateIndex] = newFirstToken
    ..[secondDateIndex] = newSecondToken;
}

// todo: нужны примеры для теста
List<DateToken> takeFromAdjacent(
  DateToken firstToken,
  DateToken secondToken,
  bool isLinked,
) {
  final firstDateCopy = AbstractDateBuilder.fromDate(firstToken.date);
  firstDateCopy.fixes &= ~secondToken.date.fixes;
  final firstCopy = DateToken(
    start: firstToken.start,
    end: firstToken.end,
    date: firstDateCopy.build(),
  );

  final secondDateCopy = AbstractDateBuilder.fromDate(secondToken.date);
  secondDateCopy.fixes &= ~firstToken.date.fixes;
  final secondCopy = DateToken(
    start: secondToken.start,
    end: secondToken.end,
    date: secondDateCopy.build(),
  );

  final newTokens = <DateToken>[];
  if (firstToken.date.minFixed.index > secondCopy.date.minFixed.index) {
    final token = collapse(firstToken, secondCopy, isLinked);
    newTokens.add(token ?? firstToken);
  } else {
    final token = collapse(secondCopy, firstToken, isLinked);
    newTokens.add(token ?? firstToken);
  }

  if (secondToken.date.minFixed.index > firstCopy.date.minFixed.index) {
    final token = collapse(secondToken, firstCopy, isLinked);
    newTokens.add(token ?? secondToken);
  } else {
    final token = collapse(firstCopy, secondToken, isLinked);
    newTokens.add(token ?? secondToken);
  }

  return newTokens.toList(growable: false);
}

void collapseClosest(
  Match match,
  ParsingData data,
  int group,
) {
  final tokens = data.tokens;

  final firstDateIndex = tokens.indexWhere(
    (token) => token.symbol == '@',
    match.start,
  );
  final secondDateIndex = tokens.indexWhere(
    (token) => token.symbol == '@',
    firstDateIndex + 1,
  );

  final firstDate = tokens[firstDateIndex] as DateToken;
  final secondDate = tokens[secondDateIndex] as DateToken;

  if (!canCollapse(firstDate.date, secondDate.date)) {
    return;
  }

  DateToken newFirst;
  DateToken newSecond;
  if (firstDate.date.minFixed.index > secondDate.date.minFixed.index) {
    newFirst = collapse(firstDate, secondDate, true) ?? firstDate;
    newSecond = secondDate;
  } else {
    newFirst = firstDate;
    newSecond = collapse(secondDate, firstDate, true) ?? secondDate;
  }

  final int duplicateGroup;
  if (firstDate.date.duplicateGroup != null) {
    duplicateGroup = firstDate.date.duplicateGroup!;
  } else if (secondDate.date.duplicateGroup != null) {
    duplicateGroup = secondDate.date.duplicateGroup!;
  } else {
    duplicateGroup = group;
  }

  // todo: some code improvement
  newFirst = DateToken(
    start: newFirst.start,
    end: newFirst.end,
    date: newFirst.date.withDuplicateGroup(duplicateGroup),
  );

  newSecond = DateToken(
    start: newSecond.start,
    end: newSecond.end,
    date: newSecond.date.withDuplicateGroup(duplicateGroup),
  );

  // todo
  tokens
    ..[firstDateIndex] = newFirst
    ..[secondDateIndex] = newSecond;
}

List<DateTimeToken> getFinalTokens(
  DateTime fromDatetime,
  ParsingData data,
) {
  final regexp = RegExp(r'(([fo]?(@)t(@))|([fo]?(@)))');
  final tokens = regexp
      .allMatches(data.pattern)
      .map((match) => parseFinalToken(
            fromDatetime,
            match,
            data.tokens.sublist(match.start, match.end),
          ))
      .toList(growable: false);

  return tokens;
}

DateTimeToken parseFinalToken(
  DateTime fromDatetime,
  Match match,
  List<Token> tokens,
) {
  // todo
  final DateTimeToken token;
  if (match.group(3) != null && match.group(4) != null) {
    // if we match a period
    // from date to date
    final firstDateIndex = tokens.indexWhere((token) => token.symbol == '@');
    final secondDateIndex = tokens.indexWhere(
      (token) => token.symbol == '@',
      firstDateIndex + 1,
    );

    DateToken firstDate = tokens[firstDateIndex] as DateToken;
    DateToken secondDate = tokens[secondDateIndex] as DateToken;

    final dates = takeFromAdjacent(firstDate, secondDate, true);
    firstDate = dates[0];
    secondDate = dates[1];

    final fromToken = convertToken(firstDate, fromDatetime);
    final toToken = convertToken(secondDate, fromDatetime);
    DateTime dateTo = toToken.date;

    final resolution = secondDate.date.maxFixed;
    while (dateTo.isBefore(fromToken.date)) {
      // ignore: missing_enum_constant_in_switch
      switch (resolution) {
        case FixPeriod.time:
          dateTo = dateTo.add(Duration(days: 1));
          break;
        case FixPeriod.day:
          dateTo = dateTo.add(Duration(days: 7));
          break;
        case FixPeriod.week:
          // todo: add month?
          dateTo = dateTo.add(Duration(days: 30));
          break;
        case FixPeriod.month:
          // todo: add year?
          dateTo = dateTo.add(Duration(days: 365));
          break;
        default:
          dateTo = dateTo.add(Duration(hours: 12));
          break;
      }
    }

    token = DateTimeToken(
      date: fromToken.date,
      dateTo: dateTo,
      start: fromToken.start,
      end: toToken.end,
      type: DateTimeTokenType.period,
      hasTime: fromToken.hasTime || toToken.hasTime,
    );
  } else {
    // this is single date
    final dateToken =
        tokens.firstWhere((token) => token.symbol == '@') as DateToken;
    token = convertToken(dateToken, fromDatetime);
    print(token);
  }

  // todo start and end
  // todo index to text

  return token;
}

enum DateTimeTokenType {
  fixed,
  period,
  spanForward,
  spanBackward,
}

// todo duplicates
@immutable
class DateTimeToken {
  final DateTime date;
  final DateTime? dateTo;
  final Duration? span;
  final bool hasTime;
  final int start;
  final int end;
  final DateTimeTokenType type;
  final int? duplicateGroup;

  const DateTimeToken({
    required this.date,
    this.dateTo,
    this.span,
    this.hasTime = false,
    required this.start,
    required this.end,
    required this.type,
    this.duplicateGroup,
  });

  @override
  String toString() => 'DateTimeToken($date)';
}

class DateTimeTokenBuilder {
  DateTime? date;
  DateTime? dateTo;
  Duration? span;
  bool hasTime = false;
  int start;
  int end;
  DateTimeTokenType type = DateTimeTokenType.fixed;
  int? duplicateGroup;

  DateTimeTokenBuilder({
    required this.start,
    required this.end,
  });

  DateTimeToken build() {
    return DateTimeToken(
      date: date!,
      dateTo: dateTo,
      span: span,
      hasTime: hasTime,
      start: start,
      end: end,
      type: type,
      duplicateGroup: duplicateGroup,
    );
  }
}

DateTimeToken convertToken(DateToken token, DateTime fromDatetime) {
  final minFixed = token.date.minFixed;
  final dateBuilder = AbstractDateBuilder.fromDate(token.date);
  dateBuilder.fixDownTo(minFixed);

  // ignore: missing_enum_constant_in_switch
  switch (minFixed) {
    case FixPeriod.time:
    case FixPeriod.timeUncertain:
      dateBuilder.date = fromDatetime;
      break;
    case FixPeriod.day:
      final userDow = fromDatetime.weekday;
      final dateDow = dateBuilder.date!.weekday;
      int diff = dateDow - userDow;
      if (diff <= 0) {
        diff += 7;
      }
      final newDate = fromDatetime.add(Duration(days: diff));
      dateBuilder.date = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
      );
      break;
    case FixPeriod.month:
      dateBuilder.date = DateTime(
        fromDatetime.isAfter(dateBuilder.date!)
            ? fromDatetime.year + 1
            : fromDatetime.year,
        dateBuilder.date!.month,
        dateBuilder.date!.day,
      );
      break;
  }

  if (dateBuilder.isFixed(FixPeriod.time) ||
      dateBuilder.isFixed(FixPeriod.timeUncertain)) {
    dateBuilder.date = DateTime(
      dateBuilder.date!.year,
      dateBuilder.date!.month,
      dateBuilder.date!.day,
      dateBuilder.time!.hours,
      dateBuilder.time!.minutes,
    );
  } else {
    dateBuilder.date = DateTime(
      dateBuilder.date!.year,
      dateBuilder.date!.month,
      dateBuilder.date!.day,
    );
  }

  final builder = DateTimeTokenBuilder(
    start: token.start,
    end: token.end,
  );

  builder.duplicateGroup = token.date.duplicateGroup;

  // ignore: missing_enum_constant_in_switch
  switch (dateBuilder.maxFixed) {
    case FixPeriod.time:
    case FixPeriod.timeUncertain:
      builder.type = DateTimeTokenType.fixed;
      builder.date = dateBuilder.date;
      builder.dateTo = dateBuilder.date;
      builder.hasTime = true;
      break;
    case FixPeriod.day:
      builder.type = DateTimeTokenType.fixed;
      builder.date = dateBuilder.date;
      builder.dateTo = dateBuilder.date!.add(almostOneDay);
      break;
    case FixPeriod.week:
      final weekday = dateBuilder.date!.weekday;
      builder.type = DateTimeTokenType.period;
      builder.date = dateBuilder.date!.add(Duration(days: 1 - weekday));
      builder.dateTo =
          dateBuilder.date!.add(Duration(days: 7 - weekday)).add(almostOneDay);
      break;
    case FixPeriod.month:
      builder.type = DateTimeTokenType.period;
      builder.date = DateTime(
        dateBuilder.date!.year,
        dateBuilder.date!.month,
        1,
      );
      builder.dateTo = DateTime(
        dateBuilder.date!.year,
        dateBuilder.date!.month,
        getDaysInMonth(dateBuilder.date!.year, dateBuilder.date!.month),
        23,
        59,
        59,
        999,
      );
      break;
    case FixPeriod.year:
      builder.type = DateTimeTokenType.period;
      builder.date = DateTime(
        dateBuilder.date!.year,
        1,
        1,
      );
      builder.dateTo = DateTime(
        dateBuilder.date!.year,
        12,
        31,
        23,
        59,
        59,
        999,
      );
      break;
  }

  if (dateBuilder.spanDirection != 0) {
    builder.type = dateBuilder.spanDirection > 0
        ? DateTimeTokenType.spanForward
        : DateTimeTokenType.spanBackward;
    builder.span = dateBuilder.span;
  }

  return builder.build();
}

const Duration almostOneDay = Duration(
  hours: 23,
  minutes: 59,
  seconds: 59,
  milliseconds: 999,
);
