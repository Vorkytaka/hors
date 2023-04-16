import 'package:hors/hors.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

/// This tests is just port of original C# tests
/// We need it for backward compatibility
/// https://github.com/DenisNP/Hors/blob/master/Hors.Tests/HorsTests.cs
void main() {
  final hors = Hors(
    recognizers: Recognizer.all,
    tokenParsers: TokenParsers.all,
  );

  test(
    'January',
    () {
      final result = hors.parse(
        '10 января событие',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.fixed);
      expect(date.date.day, 10);
      expect(date.date.month, 1);
      expect(date.date.year, 2020);
    },
  );

  test(
    'Time Period Before Day',
    () {
      final result = hors.parse(
        'С 5 до 7 вечера в понедельник будет событие',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.period);
      expect(date.date.hour, 17);
      expect(date.dateTo?.hour, 19);
      expect(date.date.day, 14);
      expect(date.dateTo?.day, 14);
    },
  );

  test(
    'Time Period Simple',
    () {
      final result = hors.parse(
        'с 10 до 13 событие',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.period);
      expect(date.date.hour, 10);
      expect(date.dateTo?.hour, 13);
    },
  );

  test(
    'Time Period Uncertain',
    () {
      final result = hors.parse(
        'с 2 до 5 событие',
        DateTime(2019, 10, 13),
        1,
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.period);
      expect(date.date.hour, 14);
      expect(date.dateTo?.hour, 17);
    },
  );

  test('Daytime', () {
    final result = hors.parse(
      'Завтра в час обед и продлится он час с небольшим',
      DateTime(2019, 10, 14),
      3,
    );

    expect(result.tokens.length, 1);
    final date = result.tokens.first;
    expect(date.type, DateTimeTokenType.fixed);
    expect(date.date.year, 2019);
    expect(date.date.month, 10);
    expect(date.date.day, 15);
    expect(date.date.hour, 13);
  });

  test(
    'Nighttime',
    () {
      final result = hors.parse(
        'Завтра в 2 ночи полнолуние, а затем в 3 часа ночи новолуние и наконец в 12 часов ночи игра.',
        DateTime(2020, 01, 01),
      );

      expect(result.tokens.length, 3);

      final firstDate = result.tokens[0];
      expect(firstDate.type, DateTimeTokenType.fixed);
      expect(firstDate.date.hour, 2);

      // todo: wrong date?
      final secondDate = result.tokens[1];
      expect(secondDate.type, DateTimeTokenType.fixed);
      expect(secondDate.date.hour, 3);

      // todo: wrong date?
      final thirdDate = result.tokens[2];
      expect(thirdDate.type, DateTimeTokenType.fixed);
      expect(thirdDate.date.hour, 0);
      expect(thirdDate.date.day, 1);
    },
  );

  test(
    'Next Month',
    () {
      final result = hors.parse(
        'В следующем месяце',
        DateTime(2019, 10, 14),
        3,
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.period);
      expect(date.date.year, 2019);
      expect(date.date.month, 11);
      expect(date.date.day, 1);
      expect(date.dateTo?.month, 11);
      expect(date.dateTo?.day, 30);
    },
  );

  test(
    'Evening',
    () {
      final result = hors.parse(
        'Завтра вечером кино',
        DateTime(2019, 10, 16),
        3,
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.period);
      expect(date.date.hour, 15);
      expect(date.dateTo?.hour, 23);
    },
  );

  test(
    'Collapse Complex',
    () {
      final result = hors.parse(
        'В понедельник в 9 и 10 вечера',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 2);

      final firstDate = result.tokens[0];
      expect(firstDate.date.year, 2019);
      expect(firstDate.date.day, 14);
      expect(firstDate.date.hour, 21);

      final secondDate = result.tokens[1];
      expect(secondDate.date.day, 14);
      expect(secondDate.date.hour, 22);
    },
  );

  test(
    'Collapse Complex Reverse',
    () {
      final result = hors.parse(
        'В понедельник в 10 и 9 вечера',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 2);

      final firstDate = result.tokens[0];
      expect(firstDate.date.year, 2019);
      expect(firstDate.date.day, 14);
      expect(firstDate.date.hour, 22);

      final secondDate = result.tokens[1];
      expect(secondDate.date.day, 14);
      expect(secondDate.date.hour, 21);
    },
  );

  test(
    'Multiple Simple',
    () {
      final result = hors.parse(
        'Позавчера в 6:30 состоялось совещание, а завтра днём будет хорошая погода.',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 2);

      final firstDate = result.tokens[0];
      expect(firstDate.date.year, 2019);
      expect(firstDate.date.day, 11);
      expect(firstDate.date.hour, 6);
      expect(firstDate.date.minute, 30);

      final secondDate = result.tokens[1];
      expect(secondDate.date.year, 2019);
      expect(secondDate.date.day, 14);
      expect(secondDate.hasTime, true);
    },
  );

  test(
    'Collapse Direction',
    () {
      final inputs = [
        'В следующем месяце с понедельника буду ходить в спортзал!',
        'С понедельника в следующем месяце буду ходить в спортзал!',
      ];

      for (final input in inputs) {
        final result = hors.parse(
          input,
          DateTime(2019, 10, 15),
          3,
        );

        expect(result.tokens.length, 1);
        final date = result.tokens.first;
        expect(date.date.year, 2019);
        expect(date.date.month, 11);
        expect(date.date.day, 4);
      }
    },
  );

  test(
    'Weekday',
    () {
      var result = hors.parse(
        'В следующем месяце во вторник состоится событие',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 1);
      var date = result.tokens.first;
      expect(date.date.year, 2019);
      expect(date.date.month, 11);
      expect(date.date.day, 5);

      result = hors.parse(
        'Через месяц во вторник состоится событие',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 1);
      date = result.tokens.first;
      expect(date.date.year, 2019);
      expect(date.date.month, 11);
      expect(date.date.day, 12);
    },
  );

  test(
    'Punctuation And Indexes',
    () {
      var result = hors.parse(
        'Через месяц, неделю и 2 дня состоится событие!',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 1);
      expect(result.textWithoutDates, 'состоится событие!');

      result = hors.parse(
        '=== 26!%;марта   в 18:00 , , , будет *** экзамен!!',
        DateTime(2019, 10, 13),
        3,
      );

      // todo:
      // expect(result.tokens.length, 1);
      // expect(result.textWithoutDates, '=== , , , будет *** экзамен!!');
    },
  );

  test(
    'Collapse Distance Date',
    () {
      final result = hors.parse(
        'на следующей неделе будет событие в пятницу и будет оно в 12',
        DateTime(2019, 10, 8),
        3,
      );

      // todo
      // expect(result.tokens.length, 1);
      // todo: text
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.fixed);
      expect(date.date.day, 18);
      expect(date.date.hour, 12);
    },
  );

  // test(
  //   '',
  //   () {
  //     final result = hors.parse(
  //       text,
  //       fromDatetime,
  //     );
  //
  //     expect(result.tokens.length, 1);
  //     final date = result.tokens.first;
  //   },
  // );
}
