import '../data.dart';

/// Plural parsers option mode.
enum ParserPluralOption {
  /// Used for indicate, that any form will be successful parsed.
  all,

  /// Used for indicate, that only singular worlds will be successful parsed.
  singular,

  /// Used for indicate, that only plural will be successful parsed.
  plural,
}

/// Base class for parsing words to symbol.
abstract class TokenParser {
  const TokenParser({
    required this.metaSymbol,
  }) : assert(metaSymbol.length == 1);

  /// Meta symbol of this token.
  /// Must be one symbol.
  ///
  /// For example: Y for year.
  final String metaSymbol;

  /// Parse input [rawWord] for current symbol.
  ///
  /// Must return [metaSymbol] if this [rawWord] is belong to current parsing form.
  /// null otherwise.
  ///
  /// Optional [option] argument is used for indicate what form of parsing will be parsed successful.
  String? parse(
    String rawWord, [
    ParserPluralOption option = ParserPluralOption.all,
  ]);
}

/// Parser that
class PluralTokenParser extends TokenParser {
  const PluralTokenParser({
    required this.normalForms,
    required this.forms,
    required super.metaSymbol,
  }) : assert(metaSymbol.length == 1);

  /// Normal form of the token that you need to parse.
  ///
  /// For example: [год]
  final List<String> normalForms;

  /// All possible forms for token with their plural indication.
  ///
  /// See [ParserPluralOption] for more info.
  ///
  ///
  /// For example:
  /// ```
  /// {
  ///   'год': 1,
  ///   'года': 1,
  ///   'году': 1,
  ///   'годом': 1,
  ///   'годе': 1,
  ///   'годов': 2,
  ///   'годам': 2,
  ///   'годами': 2,
  ///   'годах': 2,
  ///   'годы': 2,
  ///   'лета': 2,
  ///   'лет': 2,
  ///   'летам': 2,
  ///   'летами': 2,
  ///   'летах': 2,
  /// }
  /// ```
  ///
  /// Possible plurals numbers:
  /// - 0 – for any form
  /// - 1 – for singular
  /// - 2 – for plurals
  final Map<String, int> forms;

  @override
  String? parse(
    String rawWord, [
    ParserPluralOption option = ParserPluralOption.all,
  ]) {
    if (normalForms.contains(rawWord)) {
      return metaSymbol;
    }

    for (final word in forms.keys) {
      if (rawWord == word) {
        final plurals = forms[rawWord];
        if (option == ParserPluralOption.all ||
            plurals == 0 ||
            (option == ParserPluralOption.singular && plurals == 1) ||
            (option == ParserPluralOption.plural && plurals == 2)) {
          return metaSymbol;
        }
      }
    }
    return null;
  }

  @override
  String toString() => 'PluralToken($metaSymbol for $normalForms)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluralTokenParser &&
          runtimeType == other.runtimeType &&
          normalForms == other.normalForms &&
          forms == other.forms &&
          metaSymbol == other.metaSymbol;

  @override
  int get hashCode => Object.hash(normalForms, forms, metaSymbol);
}

/// Extended plural parser, for parser that can have some relative parsers with order.
///
/// Currently used for weekdays and months, to indicate value of specific weekday/month.
class OrderPluralTokenParser extends PluralTokenParser {
  const OrderPluralTokenParser({
    required super.normalForms,
    required super.forms,
    required super.metaSymbol,
    required this.order,
  });

  /// Order of current parser
  ///
  /// For example:
  /// order | weekday
  /// -|-
  /// 1 | monday
  /// 2 | tuesday
  /// 3 | wednesday
  /// etc.
  final int order;

  /// Used to find order by word, instead of symbol.
  int? parseOrder(String rawWord) {
    final symbol = parse(rawWord);
    return symbol != null ? order : null;
  }
}

extension OrderPluralTokenParserListUtils on List<OrderPluralTokenParser> {
  /// Utility method, that find [order] of specific parser in the list.
  int? parseOrder(String rawWord) {
    for (final parser in this) {
      final order = parser.parseOrder(rawWord);
      if (order != null) return order;
    }
    return null;
  }
}

/// Parser that will parse integers into symbol.
///
/// Currently used for recognize big or small numbers.
class IntegerTokenParser extends TokenParser {
  const IntegerTokenParser({
    required this.validator,
    required super.metaSymbol,
  });

  /// Validator for integer of this token.
  /// Should return [true] if this integer is valid for this token.
  /// [false] otherwise.
  final bool Function(int integer) validator;

  @override
  String? parse(
    String rawWord, [
    ParserPluralOption option = ParserPluralOption.all,
  ]) {
    final integer = int.tryParse(rawWord);
    if (integer != null) {
      if (validator(integer)) {
        return metaSymbol;
      }
    }

    return null;
  }

  @override
  String toString() => 'IntegerToken($metaSymbol)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntegerTokenParser &&
          runtimeType == other.runtimeType &&
          validator == other.validator;

  @override
  int get hashCode => Object.hash(metaSymbol, validator);
}

extension PluralTokenParserUtils on PluralTokenParser {
  /// Utility method that helps us create [MaybeDateToken] from any plural token.
  ///
  /// Currently used for replace some tokens with another.
  MaybeDateToken toMaybeDateToken(int start, int end) => MaybeDateToken(
        text: normalForms.first,
        symbol: metaSymbol,
        start: start,
        end: end,
      );
}
