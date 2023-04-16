import 'package:hors/hors.dart';

void main() {
  final hors = Hors(
    recognizers: Recognizer.all,
    tokenParsers: TokenParsers.all,
  );

  hors.parse(
    'Завтра пойду какать в 19 часов',
    DateTime.now(),
  );
}
