import 'dart:math';

import 'package:meta/meta.dart';

import 'data.dart';
import 'hors.dart';
import 'utils.dart';

@internal
bool collapseDates(
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

@internal
bool canCollapse(DateToken firstToken, DateToken secondToken) {
  if ((firstToken.fixed & secondToken.fixed) != 0) return false;
  return firstToken.spanDirection != -secondToken.spanDirection ||
      firstToken.spanDirection == 0;
}

@internal
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

@internal
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
@internal
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
@internal
List<DateToken> takeFromAdjacent(
  DateToken firstToken,
  DateToken secondToken,
  bool isLinked,
) {
  final firstCopy = firstToken.copy();
  firstCopy.fixed &= ~secondToken.fixed;

  final secondCopy = secondToken.copy();
  secondCopy.fixed &= ~firstToken.fixed;

  final newTokens = <DateToken>[];
  if (firstToken.minFixed.index > secondCopy.minFixed.index) {
    final token = collapse(firstToken, secondCopy, isLinked);
    newTokens.add(token ?? firstToken);
  } else {
    DateToken? token = collapse(secondCopy, firstToken, isLinked);
    token = token?.copy(
      start: firstToken.start,
      end: firstToken.end,
    );
    newTokens.add(token ?? firstToken);
  }

  if (secondToken.minFixed.index > firstCopy.minFixed.index) {
    final token = collapse(secondToken, firstCopy, isLinked);
    newTokens.add(token ?? secondToken);
  } else {
    DateToken? token = collapse(firstCopy, secondToken, isLinked);
    token = token?.copy(
      start: secondToken.start,
      end: secondToken.end,
    );
    newTokens.add(token ?? secondToken);
  }

  return newTokens.toList(growable: false);
}

@internal
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

  // We should return edges to the tokens,
  // because they only collapsed logically,
  // but they still stay far from each other
  newFirst = newFirst.copy(
    start: firstDate.start,
    end: firstDate.end,
  );
  newSecond = newSecond.copy(
    start: secondDate.start,
    end: secondDate.end,
  );

  tokens
    ..[firstDateIndex] = newFirst
    ..[secondDateIndex] = newSecond;

  return true;
}

@internal
List<DateTimeToken> getFinalTokens(
  DateTime fromDatetime,
  ParsingData data,
) {
  final regexp = RegExp(r'(([fo]?(@)t(@))|([fo]?(@)))');
  final tokens = <DateTimeToken>[];
  final duplicates = <int, List<DateTimeTokenCarcase>>{};
  final matches = regexp.allMatches(data.pattern);

  for (final match in matches) {
    final carcase = parseFinalToken(
      fromDatetime,
      match,
      data,
    );

    if (carcase.duplicateGroup == null) {
      tokens.add(carcase.build());
    } else {
      final currentDuplicates = duplicates[carcase.duplicateGroup];
      if (currentDuplicates != null) {
        duplicates[carcase.duplicateGroup!]!.add(carcase);
      } else {
        duplicates[carcase.duplicateGroup!] = [carcase];
      }
    }
  }

  for (final dups in duplicates.values) {
    final main = dups.reduce(
      (max, curr) => curr.fixed > max.fixed ? curr : max,
    );
    final ranges = dups.map((carcase) => IntRange(
          start: carcase.start,
          end: carcase.end,
        ));

    tokens.add(
      DateTimeToken(
        date: main.date!,
        dateTo: main.dateTo,
        span: main.span,
        hasTime: main.hasTime,
        ranges: ranges.toList(growable: false),
        type: main.type,
      ),
    );
  }

  return tokens.toList(growable: false);
}

@internal
DateTimeTokenCarcase parseFinalToken(
  DateTime fromDatetime,
  Match match,
  ParsingData data,
) {
  final tokens = data.tokens;
  final DateTimeTokenCarcase carcase;
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
    DateTime dateTo = toToken.date!;

    final resolution = secondDate.maxFixed;
    while (dateTo.isBefore(fromToken.date!)) {
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

    carcase = DateTimeTokenCarcase(
      start: fromToken.start,
      end: toToken.end,
    )
      ..date = fromToken.date!
      ..dateTo = dateTo
      ..type = DateTimeTokenType.period
      ..hasTime = fromToken.hasTime || toToken.hasTime
      ..fixed = fromToken.fixed;
  } else {
    // this is single date
    final dateTokenIndex = tokens.indexWhere(
      (token) => token.symbol == '@',
      match.start,
    );
    final dateToken = tokens[dateTokenIndex] as DateToken;
    carcase = convertToken(dateToken, fromDatetime);
  }

  carcase.start = data.tokens[match.start].start;
  carcase.end = data.tokens[match.end - 1].end;

  // todo start and end
  // todo index to text

  return carcase;
}

@internal
DateTimeTokenCarcase convertToken(DateToken token, DateTime fromDatetime) {
  final carcase = DateTimeTokenCarcase(
    start: token.start,
    end: token.end,
  );

  carcase.duplicateGroup = token.duplicateGroup;
  carcase.fixed = token.fixed;

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

  // Used for period of days
  const Duration almostOneDay = Duration(
    hours: 23,
    minutes: 59,
    seconds: 59,
    milliseconds: 999,
  );

  // ignore: missing_enum_constant_in_switch
  switch (token.maxFixed) {
    case FixPeriod.time:
    case FixPeriod.timeUncertain:
      carcase.type = DateTimeTokenType.fixed;
      carcase.date = token.date;
      carcase.dateTo = token.date;
      carcase.hasTime = true;
      break;
    case FixPeriod.day:
      carcase.type = DateTimeTokenType.fixed;
      carcase.date = token.date;
      carcase.dateTo = token.date!.add(almostOneDay);
      break;
    case FixPeriod.week:
      final weekday = token.date!.weekday;
      carcase.type = DateTimeTokenType.period;
      carcase.date = token.date!.add(Duration(days: 1 - weekday));
      carcase.dateTo =
          token.date!.add(Duration(days: 7 - weekday)).add(almostOneDay);
      break;
    case FixPeriod.month:
      carcase.type = DateTimeTokenType.period;
      carcase.date = DateTime(
        token.date!.year,
        token.date!.month,
        1,
      );
      carcase.dateTo = DateTime(
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
      carcase.type = DateTimeTokenType.period;
      carcase.date = DateTime(
        token.date!.year,
        1,
        1,
      );
      carcase.dateTo = DateTime(
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
    carcase.type = token.spanDirection > 0
        ? DateTimeTokenType.spanForward
        : DateTimeTokenType.spanBackward;
    carcase.span = token.span;
  }

  return carcase;
}

/// TODO: Docs
@internal
void parsing(
  ParsingData data,
  RegExp regexp,
  bool Function(Match match, ParsingData data) parser,
) {
  // We use reversed data, because our data is mutable,
  // so, when we parse and mutate this data from the end
  // then it doesn't affect matches at a start.
  final matches =
      regexp.allMatches(data.pattern).toList(growable: false).reversed;

  if (matches.isEmpty) {
    return;
  }

  bool updatePattern = false;
  for (final match in matches) {
    updatePattern = parser(match, data) || updatePattern;
  }

  if (updatePattern) {
    data.updatePattern();
  }
}
