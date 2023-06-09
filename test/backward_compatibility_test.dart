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

      final secondDate = result.tokens[1];
      expect(secondDate.type, DateTimeTokenType.fixed);
      expect(secondDate.date.hour, 3);

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
      expect(result.textWithoutTokens, 'Состоится событие!');

      result = hors.parse(
        '=== 26!%;марта   в 18:00 , , , будет *** экзамен!!',
        DateTime(2019, 10, 13),
        3,
      );

      expect(result.tokens.length, 1);
      expect(result.textWithoutTokens, '=== , , , будет *** экзамен!!');
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

      expect(result.tokens.length, 1);
      expect(result.textWithoutTokens, 'Будет событие и будет оно');
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.fixed);
      expect(date.date.day, 18);
      expect(date.date.hour, 12);
    },
  );

  test(
    'Collapse Distance Time',
    () {
      var result = hors.parse(
        'в четверг будет событие в 16 0 0',
        DateTime(2019, 10, 8),
        3,
      );

      expect(result.tokens.length, 1);
      expect(result.textWithoutTokens, 'Будет событие');
      var date = result.tokens.first;
      expect(date.type, DateTimeTokenType.fixed);
      expect(date.hasTime, true);
      expect(date.date.hour, 16);
      expect(date.date.day, 10);

      result = hors.parse(
        'завтра встреча с другом в 12',
        DateTime(2019, 10, 11),
        5,
      );

      expect(result.tokens.length, 1);
      date = result.tokens.first;
      expect(date.type, DateTimeTokenType.fixed);
      expect(date.hasTime, true);
      expect(date.date.hour, 12);
      expect(date.date.day, 12);

      result = hors.parse(
        'в четверг будет хорошее событие в 16 0 0',
        DateTime(2019, 10, 8),
        2,
      );

      expect(result.tokens.length, 2);
      final dateFirst = result.tokens[0];
      final dateLast = result.tokens[1];
      expect(dateFirst.type, DateTimeTokenType.fixed);
      expect(dateFirst.hasTime, false);
      expect(dateLast.hasTime, true);
      expect(dateLast.date.hour, 16);
      expect(dateFirst.date.day, 10);
    },
  );

  test(
    'Time After Day',
    () {
      final result = hors.parse(
        'в четверг 16 0 0 будет событие',
        DateTime(2019, 10, 8),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.fixed);
      expect(date.hasTime, true);
      expect(date.date.hour, 16);
      expect(date.date.day, 10);
    },
  );

  test(
    'Time Period',
    () {
      final result = hors.parse(
        'В следующий четверг с 9 утра до 6 вечера важный экзамен!',
        DateTime(2019, 9, 7),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.period);
      expect(date.hasTime, true);
      expect(date.date.hour, 9);
      expect(date.date.day, 12);
      expect(date.date.month, 9);
      expect(date.dateTo?.hour, 18);
      expect(date.dateTo?.day, 12);
      expect(date.dateTo?.month, 9);
      expect(date.date.year, 2019);
      expect(date.dateTo?.year, 2019);
    },
  );

  test(
    'Complex Period',
    () {
      final result = hors.parse(
        'хакатон с 12 часов 18 сентября до 12 часов 20 сентября',
        DateTime(2019, 7, 7),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.period);
      expect(date.hasTime, true);
      expect(date.date.hour, 12);
      expect(date.date.day, 18);
      expect(date.date.month, 9);
      expect(date.dateTo?.hour, 12);
      expect(date.dateTo?.day, 20);
      expect(date.dateTo?.month, 9);
      expect(date.date.year, 2019);
      expect(date.dateTo?.year, 2019);
    },
  );

  test(
    'Time Before Day',
    () {
      final result = hors.parse(
        '12 часов 12 сентября будет встреча',
        DateTime(2019, 9, 7),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.fixed);
      expect(date.hasTime, true);
      expect(date.date.hour, 12);
      expect(date.date.day, 12);
      expect(date.date.month, 9);
    },
  );

  test(
    'Time Hour Of Day',
    () {
      final result = hors.parse(
        '24 сентября в час дня',
        DateTime(2019, 9, 7),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.fixed);
      expect(date.hasTime, true);
      expect(date.date.hour, 13);
    },
  );

  test(
    'Fix Period',
    () {
      final result = hors.parse(
        'на выходных будет хорошо',
        DateTime(2019, 9, 7),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.period);
      expect(date.date.day, 14);
      expect(date.dateTo?.day, 15);
    },
  );

  test(
    'Dates Period',
    () {
      final strings = [
        'с 11 по 15 сентября будет командировка',
        '11 по 15 сентября будет командировка',
        'с 11 до 15 сентября будет командировка',
      ];

      for (final string in strings) {
        final result = hors.parse(
          string,
          DateTime(2019, 8, 6),
        );

        expect(result.tokens.length, 1);
        final date = result.tokens.first;

        expect(date.type, DateTimeTokenType.period);
        expect(date.date.day, 11);
        expect(date.dateTo?.day, 15);
        expect(date.date.month, 9);
        expect(date.dateTo?.month, 9);
      }

      final result = hors.parse(
        'с 11 до 15 числа будет командировка',
        DateTime(2019, 9, 6),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;
      expect(date.type, DateTimeTokenType.period);
      expect(date.date.day, 11);
      expect(date.dateTo?.day, 15);
      expect(date.date.month, 9);
      expect(date.dateTo?.month, 9);
    },
  );

  test(
    'Days Of Week',
    () {
      final result = hors.parse(
        'во вторник встреча с заказчиком',
        DateTime(2019, 9, 6),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;

      expect(date.type, DateTimeTokenType.fixed);
      expect(date.date.day, 10);
    },
  );

  test(
    'Holidays',
    () {
      final result = hors.parse(
        'в эти выходные еду на дачу',
        DateTime(2019, 9, 2),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;

      expect(date.type, DateTimeTokenType.period);
      expect(date.date.day, 7);
      expect(date.dateTo?.day, 8);
    },
  );

  test(
    'Holiday',
    () {
      final result = hors.parse(
        'пойду гулять в следующий выходной',
        DateTime(2019, 9, 2),
      );

      expect(result.tokens.length, 1);
      final date = result.tokens.first;

      expect(date.type, DateTimeTokenType.fixed);
      expect(date.date.day, 14);
      expect(date.dateTo?.day, 14);
    },
  );
}
