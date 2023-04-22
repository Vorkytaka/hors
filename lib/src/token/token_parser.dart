import '../data.dart';

/// TODO: Docs
enum ParserPluralOption {
  all,
  singular,
  plural,
}

/// TODO: Docs
abstract class TokenParser {
  const TokenParser({
    required this.metaSymbol,
  });

  /// Meta symbol of this token.
  /// Must be one symbol.
  ///
  /// For example: Y for год.
  final String metaSymbol;

  /// TODO: Docs
  String? parse(
    String rawWord, [
    ParserPluralOption option = ParserPluralOption.all,
  ]);
}

/// TODO: Docs
class PluralTokenParser extends TokenParser {
  const PluralTokenParser({
    required this.normalForms,
    required this.forms,
    required super.metaSymbol,
  }) : assert(metaSymbol.length == 1);

  /// Normal form of the token that you need to parse.
  ///
  /// For example: год
  final List<String> normalForms;

  /// All possible forms for token.
  ///
  /// For example: год, года, лет, etc.
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

/// TODO: Docs
class OrderPluralTokenParser extends PluralTokenParser {
  const OrderPluralTokenParser({
    required super.normalForms,
    required super.forms,
    required super.metaSymbol,
    required this.order,
  });

  /// Month index
  final int order;

  int? parseOrder(String rawWord) {
    final symbol = parse(rawWord);
    return symbol != null ? order : null;
  }
}

extension OrderPluralTokenParserListUtils on List<OrderPluralTokenParser> {
  int? parseOrder(String rawWord) {
    for (final parser in this) {
      final order = parser.parseOrder(rawWord);
      if (order != null) return order;
    }
    return null;
  }
}

/// TODO: Docs
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

/// TODO: Docs
extension PluralTokenParserUtils on PluralTokenParser {
  MaybeDateToken toMaybeDateToken(int start, int end) => MaybeDateToken(
        text: normalForms.first,
        symbol: metaSymbol,
        start: start,
        end: end,
      );
}
