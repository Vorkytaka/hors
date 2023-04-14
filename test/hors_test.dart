import 'package:hors/hors.dart';
import 'package:hors/src/recognizer/recognizer.dart';
import 'package:hors/src/token/token_parsers.dart';

void main() {
  final hors = Hors(
    recognizers: Recognizer.all,
    tokenParsers: TokenParsers.all,
  );

  hors.x(
    'Вчера в 10 вечера я какал и до завтра в 11 вечера надо проснуться',
    DateTime.now(),
  );
}
