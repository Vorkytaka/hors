import 'package:hors/hors.dart';
import 'package:hors/src/token/tokens.dart';

void main() {
  final hors = Hors(
    recognizers: List.empty(),
    tokens: Tokens.all,
  );

  hors.parse(
    'в следующий четверг в 9 вечера иду какац',
    DateTime.now(),
  );
}
