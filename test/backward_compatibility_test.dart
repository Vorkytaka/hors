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

  test('', () => null);
}
