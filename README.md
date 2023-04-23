# Hors

### Overview

A simple Dart package to extract date and time from natural speech.
Currently works __only__ with russian language.

### Usage

To use this package you need to create a `Hors` object with list of `TokenParser` and list
of `Recognizer`.
Out of the box there is rich collection of both types.

Base example looks like this:

```dart
import 'package:hors/hors.dart';

final hors = Hors(
  recognizers: Recognizer.all,
  tokenParsers: TokenParsers.all,
);

final result = hors.parse('Завтра состоится событие в 11 часов вечера');
```

`parse` method also has optional arguments:

- `DateTime fromDatetime` – the date relative to which the intervals are to be measured.
- `int closestSteps` – the maximum number of words between two dates at which will try to combine
  these dates into one, if possible.

### Limitations

- All numbers must be a numbers, not in words (`11 ноября`, not `одинадцатого ноября`).
