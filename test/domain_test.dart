import 'package:hors/hors.dart';
import 'package:hors/src/domain.dart';
import 'package:test/test.dart';

void main() {
  test('Combine Ranges', () {
    final values = <List<IntRange>, List<IntRange>>{
      []: [],
      [IntRange(start: 1, end: 10)]: [IntRange(start: 1, end: 10)],
      [
        IntRange(start: 0, end: 4),
        IntRange(start: 2, end: 3),
        IntRange(start: 3, end: 5),
        IntRange(start: 7, end: 9),
      ]: [
        IntRange(start: 0, end: 5),
        IntRange(start: 7, end: 9),
      ],
      [
        IntRange(start: 1, end: 10),
        IntRange(start: 10, end: 20),
      ]: [
        IntRange(start: 1, end: 20),
      ],
      [
        IntRange(start: 1, end: 10),
        IntRange(start: 11, end: 20),
      ]: [
        IntRange(start: 1, end: 10),
        IntRange(start: 11, end: 20),
      ],
      [
        IntRange(start: 1, end: 5),
        IntRange(start: 10, end: 15),
        IntRange(start: 20, end: 25),
      ]: [
        IntRange(start: 1, end: 5),
        IntRange(start: 10, end: 15),
        IntRange(start: 20, end: 25),
      ],
    };

    for (final value in values.keys) {
      final combined = combineIntRange(value);
      expect(combined, values[value]!);
    }
  });

  test('generateTextWithoutTokens', () {
    final texts = [
      'Текст номер один',
      'Завтра пойду гулять в 11 часов',
      'Напомнить в 12 28 апреля собрать вещи',
      'Какой-то текст',
    ];

    final ranges = [
      [IntRange(start: 6, end: 11)],
      [
        IntRange(start: 0, end: 6),
        IntRange(start: 20, end: 30),
      ],
      [
        IntRange(start: 10, end: 24),
      ],
      [
        IntRange(start: 0, end: 14),
      ],
    ];

    final textsWithoutTokens = [
      'Текст один',
      'Пойду гулять',
      'Напомнить собрать вещи',
      '',
    ];

    for(int i = 0; i < textsWithoutTokens.length; i++) {
      final result = generateTextWithoutTokens(texts[i], ranges[i]);
      expect(result, textsWithoutTokens[i]);
    }
  });
}
