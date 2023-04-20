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
          .toList(),
    );

    for (final recognizer in recognizers) {
      recognizer.recognize(data, fromDatetime);
    }

    final RegExp startPeriodsPattern = RegExp(r'(?<!(t))(@)(?=((N?[fo]?)(@)))');
    final RegExp endPeriodsPattern = RegExp(r'(?<=(t))(@)(?=((N?[fot]?)(@)))');

    parsing(
      data,
      startPeriodsPattern,
      collapseDates2,
    );

    parsing(
      data,
      endPeriodsPattern,
      collapseDates2,
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

    if (closestSteps > 1) {
      final regexp = RegExp('(@)[^@t]{1,$closestSteps}(?=(@))');
      int lastGroup = 0;
      parsing(
        data,
        regexp,
        (match, data) => collapseClosest(match, data, lastGroup++),
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

bool collapseDates2(
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

  if (!canCollapse(firstDate, secondDate)) {
    return false;
  }

  final DateToken? newToken;
  if (firstDate.minFixed.index < secondDate.minFixed.index) {
    newToken = collapse(secondDate, firstDate, false);
  } else {
    newToken = collapse(firstDate, secondDate, false);
  }

  if (newToken == null) return false;

  tokens.replaceRange(
    firstDateIndex,
    secondDateIndex + 1,
    [newToken],
  );

  return true;
}

bool canCollapse(DateToken firstToken, DateToken secondToken) {
  if ((firstToken.fixes & secondToken.fixes) != 0) return false;
  return firstToken.spanDirection != -secondToken.spanDirection ||
      firstToken.spanDirection == 0;
}

DateToken? collapse(DateToken baseToken, DateToken coverToken, bool isLinked) {
  if (!canCollapse(baseToken, coverToken)) {
    return null;
  }

  // todo: if base date is null?
  final newToken = baseToken.copy(
    start: min(baseToken.start, coverToken.start),
    end: max(baseToken.end, coverToken.end),
  );

  if (baseToken.spanDirection != 0 && coverToken.spanDirection != 0) {
    newToken.spanDirection = baseToken.spanDirection + coverToken.spanDirection;
  }

  if (!baseToken.isFixed(FixPeriod.year) &&
      coverToken.isFixed(FixPeriod.year)) {
    newToken.date = DateTime(
      coverToken.date!.year,
      newToken.date!.month,
      newToken.date!.day,
    );
    newToken.fix(FixPeriod.year);
  }

  if (!baseToken.isFixed(FixPeriod.month) &&
      coverToken.isFixed(FixPeriod.month)) {
    newToken.date = DateTime(
      newToken.date!.year,
      coverToken.date!.month,
      newToken.date!.day,
    );
    newToken.fix(FixPeriod.month);
  }

  if (!baseToken.isFixed(FixPeriod.week) &&
      coverToken.isFixed(FixPeriod.week)) {
    if (baseToken.isFixed(FixPeriod.day)) {
      newToken.date = takeDayOfWeekFrom(coverToken.date!, newToken.date!);
      newToken.fix(FixPeriod.week);
    } else if (!coverToken.isFixed(FixPeriod.day)) {
      newToken.date = DateTime(
        newToken.date!.year,
        newToken.date!.month,
        coverToken.date!.day,
      );
      newToken.fix(FixPeriod.week);
    }
  } else if (baseToken.isFixed(FixPeriod.week) &&
      coverToken.isFixed(FixPeriod.day)) {
    newToken.date = takeDayOfWeekFrom(newToken.date!, coverToken.date!);
    newToken.fix(FixPeriod.week);
    newToken.fix(FixPeriod.day);
  }

  if (!baseToken.isFixed(FixPeriod.day) && coverToken.isFixed(FixPeriod.day)) {
    if (coverToken.fixDayOfWeek) {
      final current = DateTime(
        newToken.date!.year,
        newToken.date!.month,
        newToken.isFixed(FixPeriod.week) ? newToken.date!.day : 0,
      );
      newToken.date = takeDayOfWeekFrom(
        current,
        coverToken.date!,
        !baseToken.isFixed(FixPeriod.week),
      );
    } else {
      newToken.date = DateTime(
        newToken.date!.year,
        newToken.date!.month,
        coverToken.date!.day,
      );
    }
    newToken.fix(FixPeriod.week);
    newToken.fix(FixPeriod.day);
  }

  bool timeGot = false;
  if (!baseToken.isFixed(FixPeriod.time) &&
      coverToken.isFixed(FixPeriod.time)) {
    newToken.fix(FixPeriod.time);
    if (!baseToken.isFixed(FixPeriod.timeUncertain)) {
      newToken.time = coverToken.time;
    } else {
      if (baseToken.time!.hours <= 12 && coverToken.time!.hours > 12) {
        if (!isLinked) {
          newToken.time = newToken.time! + Duration(hours: 12);
        }
      }
    }

    timeGot = true;
  }

  if (!baseToken.isFixed(FixPeriod.timeUncertain) &&
      coverToken.isFixed(FixPeriod.timeUncertain)) {
    newToken.fix(FixPeriod.timeUncertain);
    if (baseToken.isFixed(FixPeriod.time)) {
      final offset =
          coverToken.time!.hours <= 12 && baseToken.time!.hours > 12 ? 12 : 0;
      newToken.time = Duration(
        hours: coverToken.time!.hours + offset,
        minutes: coverToken.time!.minutes,
      );
    } else {
      newToken.time = coverToken.time;
      timeGot = true;
    }
  }

  if (timeGot &&
      baseToken.spanDirection != 0 &&
      coverToken.spanDirection == 0) {
    if (baseToken.spanDirection > 0) {
      newToken.span = baseToken.time! + baseToken.time!;
    } else {
      newToken.span = baseToken.time! - baseToken.time!;
    }
  }

  return newToken;
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
bool takeFromA(
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

  return true;
}

// todo: нужны примеры для теста
List<DateToken> takeFromAdjacent(
  DateToken firstToken,
  DateToken secondToken,
  bool isLinked,
) {
  final firstCopy = firstToken.copy();
  firstCopy.fixes &= ~secondToken.fixes;

  final secondCopy = secondToken.copy();
  secondCopy.fixes &= ~firstToken.fixes;

  final newTokens = <DateToken>[];
  if (firstToken.minFixed.index > secondCopy.minFixed.index) {
    final token = collapse(firstToken, secondCopy, isLinked);
    newTokens.add(token ?? firstToken);
  } else {
    final token = collapse(secondCopy, firstToken, isLinked);
    newTokens.add(token ?? firstToken);
  }

  if (secondToken.minFixed.index > firstCopy.minFixed.index) {
    final token = collapse(secondToken, firstCopy, isLinked);
    newTokens.add(token ?? secondToken);
  } else {
    final token = collapse(firstCopy, secondToken, isLinked);
    newTokens.add(token ?? secondToken);
  }

  return newTokens.toList(growable: false);
}

bool collapseClosest(
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

  if (!canCollapse(firstDate, secondDate)) {
    return false;
  }

  DateToken newFirst;
  DateToken newSecond;
  if (firstDate.minFixed.index > secondDate.minFixed.index) {
    newFirst = collapse(firstDate, secondDate, true) ?? firstDate;
    newSecond = secondDate;
  } else {
    newFirst = firstDate;
    newSecond = collapse(secondDate, firstDate, true) ?? secondDate;
  }

  final int duplicateGroup;
  if (firstDate.duplicateGroup != null) {
    duplicateGroup = firstDate.duplicateGroup!;
  } else if (secondDate.duplicateGroup != null) {
    duplicateGroup = secondDate.duplicateGroup!;
  } else {
    duplicateGroup = group;
  }

  newFirst.duplicateGroup = duplicateGroup;
  newSecond.duplicateGroup = duplicateGroup;

  // todo
  tokens
    ..[firstDateIndex] = newFirst
    ..[secondDateIndex] = newSecond;

  return true;
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
            data,
          ))
      .toList(growable: false);

  return tokens;
}

DateTimeToken parseFinalToken(
  DateTime fromDatetime,
  Match match,
  ParsingData data,
) {
  final tokens = data.tokens;
  // todo
  final DateTimeToken token;
  if (match.group(3) != null && match.group(4) != null) {
    // if we match a period
    // from date to date
    final firstDateIndex = tokens.indexWhere(
      (token) => token.symbol == '@',
      match.start,
    );
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

    final resolution = secondDate.maxFixed;
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
    final dateTokenIndex = tokens.indexWhere(
      (token) => token.symbol == '@',
      match.start,
    );
    final dateToken = tokens[dateTokenIndex] as DateToken;
    token = convertToken(dateToken, fromDatetime);
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
  final minFixed = token.minFixed;
  token.fixDownTo(minFixed);

  // ignore: missing_enum_constant_in_switch
  switch (minFixed) {
    case FixPeriod.time:
    case FixPeriod.timeUncertain:
      token.date = fromDatetime;
      break;
    case FixPeriod.day:
      final userDow = fromDatetime.weekday;
      final dateDow = token.date!.weekday;
      int diff = dateDow - userDow;
      if (diff <= 0) {
        diff += 7;
      }
      final newDate = fromDatetime.add(Duration(days: diff));
      token.date = DateTime(
        newDate.year,
        newDate.month,
        newDate.day,
      );
      break;
    case FixPeriod.month:
      token.date = DateTime(
        fromDatetime.isAfter(token.date!)
            ? fromDatetime.year + 1
            : fromDatetime.year,
        token.date!.month,
        token.date!.day,
      );
      break;
  }

  if (token.isFixed(FixPeriod.time) || token.isFixed(FixPeriod.timeUncertain)) {
    token.date = DateTime(
      token.date!.year,
      token.date!.month,
      token.date!.day,
      token.time!.hours,
      token.time!.minutes,
    );
  } else {
    token.date = DateTime(
      token.date!.year,
      token.date!.month,
      token.date!.day,
    );
  }

  final builder = DateTimeTokenBuilder(
    start: token.start,
    end: token.end,
  );

  builder.duplicateGroup = token.duplicateGroup;

  // ignore: missing_enum_constant_in_switch
  switch (token.maxFixed) {
    case FixPeriod.time:
    case FixPeriod.timeUncertain:
      builder.type = DateTimeTokenType.fixed;
      builder.date = token.date;
      builder.dateTo = token.date;
      builder.hasTime = true;
      break;
    case FixPeriod.day:
      builder.type = DateTimeTokenType.fixed;
      builder.date = token.date;
      builder.dateTo = token.date!.add(almostOneDay);
      break;
    case FixPeriod.week:
      final weekday = token.date!.weekday;
      builder.type = DateTimeTokenType.period;
      builder.date = token.date!.add(Duration(days: 1 - weekday));
      builder.dateTo =
          token.date!.add(Duration(days: 7 - weekday)).add(almostOneDay);
      break;
    case FixPeriod.month:
      builder.type = DateTimeTokenType.period;
      builder.date = DateTime(
        token.date!.year,
        token.date!.month,
        1,
      );
      builder.dateTo = DateTime(
        token.date!.year,
        token.date!.month,
        getDaysInMonth(token.date!.year, token.date!.month),
        23,
        59,
        59,
        999,
      );
      break;
    case FixPeriod.year:
      builder.type = DateTimeTokenType.period;
      builder.date = DateTime(
        token.date!.year,
        1,
        1,
      );
      builder.dateTo = DateTime(
        token.date!.year,
        12,
        31,
        23,
        59,
        59,
        999,
      );
      break;
  }

  if (token.spanDirection != 0) {
    builder.type = token.spanDirection > 0
        ? DateTimeTokenType.spanForward
        : DateTimeTokenType.spanBackward;
    builder.span = token.span;
  }

  return builder.build();
}

const Duration almostOneDay = Duration(
  hours: 23,
  minutes: 59,
  seconds: 59,
  milliseconds: 999,
);
