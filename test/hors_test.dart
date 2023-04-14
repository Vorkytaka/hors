import 'package:hors/hors.dart';
import 'package:hors/src/recognizer/recognizer.dart';
import 'package:hors/src/token/token_parsers.dart';

void main() {
  final hors = Hors(
    recognizers: Recognizer.all,
    tokenParsers: TokenParsers.all,
  );

  hors.x(
    'в четверг будет хорошее событие в 16 0 0',
    DateTime.now(),
  );
}
