import 'package:hors/hors.dart';
import 'package:hors/src/recognizer/recognizer.dart';
import 'package:hors/src/token/token_parsers.dart';

void main() {
  final hors = Hors(
    recognizers: Recognizer.all,
    tokenParsers: TokenParsers.all,
  );

  hors.x(
    'В 11 часов 11 минут буду срать',
    DateTime.now(),
  );
}
