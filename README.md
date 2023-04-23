# Hors

### Overview

A simple Dart package to extract date and time from natural speech.
Currently works __only__ with russian language.

### Usage

To use this package you need to create a `Hors` object with list of `TokenParser` and list
of `Recognizer`.
Out of the box there is rich collection of both types, see `Recognizer.all` and `TokenParsers.all`.

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
    - We have plans to fix this
- Some recognizers is relate with each-other, so you should know in which order they used or you can
  get unpredictable results.

### Examples

```
> Завтра состоится событие в 11 часов
	Text: Состоится событие
	DateTimeToken, fixed:
	2023-04-24 11:00:00.000

> Через 2 дня в 15 часов 30 минут к врачу
	Text: К врачу
	DateTimeToken, spanForward:
	Date:	2023-04-25 15:30:00.000
	Span:	63:30:00.000000

> Отправимся на рыбалку с 25 до 28 числа
	Text: Отправимся на рыбалку
	DateTimeToken, period:
	From:	2023-04-25 00:00:00.000
	To:		2023-04-28 00:00:00.000
```