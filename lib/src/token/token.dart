abstract class Token {
  const Token({
    required this.metaSymbol,
  });

  /// Meta symbol of this token.
  /// Must be one symbol.
  ///
  /// For example: Y for год.
  final String metaSymbol;

  String? parse(String rawWord);
}

class PluralToken extends Token {
  const PluralToken({
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
  String? parse(String rawWord) {
    if (normalForms.contains(rawWord)) {
      return metaSymbol;
    }

    for (final word in forms.keys) {
      if (rawWord == word) {
        return metaSymbol;
      }
    }
    return null;
  }

  @override
  String toString() => 'PluralToken($metaSymbol for $normalForms)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluralToken &&
          runtimeType == other.runtimeType &&
          normalForms == other.normalForms &&
          forms == other.forms &&
          metaSymbol == other.metaSymbol;

  @override
  int get hashCode => Object.hash(normalForms, forms, metaSymbol);
}

class IntegerToken extends Token {
  const IntegerToken({
    required this.validator,
    required super.metaSymbol,
  });

  /// Validator for integer of this token.
  /// Should return [true] if this integer is valid for this token.
  /// [false] otherwise.
  final bool Function(int integer) validator;

  @override
  String? parse(String rawWord) {
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
      other is IntegerToken &&
          runtimeType == other.runtimeType &&
          validator == other.validator;

  @override
  int get hashCode => Object.hash(metaSymbol, validator);
}
