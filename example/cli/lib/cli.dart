import 'dart:io';

import 'package:hors/hors.dart';

void main() async {
  stdout.write('Запуск термоядерного примера Hors 3000.\n');
  stdout.write('Введите строку для парсинга:\n\n');
  final hors = Hors(
    recognizers: Recognizer.all,
    tokenParsers: TokenParsers.all,
  );

  while (true) {
    stdout.write('> ');
    final input = stdin.readLineSync();
    if (input?.toLowerCase() == 'выход') break;

    final result = hors.parse(
      input ?? '',
      DateTime.now(),
    );

    if (result.textWithoutTokens.isNotEmpty) {
      stdout.write('\tText: ${result.textWithoutTokens}\n');
    }

    for (final token in result.tokens) {
      stdout.write('\t');
      stdout.write(token);
      stdout.write('\n');
    }

    stdout.write('\n');
  }
}
