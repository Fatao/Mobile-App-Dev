/// Ошибка вычисления. Сообщение можно показывать пользователю как есть.
class CalculatorException implements Exception {
  const CalculatorException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Чистая бизнес-логика: разбор и вычисление выражений.
/// Ничего не знает о виджетах и состоянии интерфейса.
class CalculatorLogic {
  CalculatorLogic._();

  static const String plus = '+';
  static const String minus = '−';
  static const String times = '×';
  static const String divide = '÷';
  static const List<String> operators = [plus, minus, times, divide];

  /// Числа длиннее этого порога не показываем, чтобы не получить запись вида 1e+20.
  static const double maxAbsValue = 1e15;

  static bool isOperator(String ch) => operators.contains(ch);

  /// Цифра или десятичная точка.
  static bool isNumberChar(String ch) {
    if (ch == '.') return true;
    final code = ch.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  /// Вычисляет выражение с учётом приоритета операций (× и ÷ раньше + и −).
  /// Допускает унарный минус: «5×−3».
  static double evaluate(String expression) {
    final tokens = _tokenize(expression);
    if (tokens.isEmpty) {
      throw const CalculatorException('Пустое выражение');
    }
    final value = _Parser(tokens).parse();
    if (value.isNaN || value.isInfinite) {
      throw const CalculatorException('Некорректная операция');
    }
    if (value.abs() >= maxAbsValue) {
      throw const CalculatorException('Слишком большое число');
    }
    return value;
  }

  /// Форматирует число для показа: 13.0 -> «13», 0.30000000000000004 -> «0.3».
  static String format(double value) {
    if (value == 0) return '0';
    var text = value.toStringAsFixed(10);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    if (text == '-0') return '0';
    return text.startsWith('-') ? '$minus${text.substring(1)}' : text;
  }

  static String _normalizeOperator(String ch) {
    switch (ch) {
      case '-':
        return minus;
      case '*':
        return times;
      case '/':
        return divide;
    }
    if (isOperator(ch)) return ch;
    throw const CalculatorException('Недопустимый символ');
  }

  static List<Object> _tokenize(String expression) {
    final tokens = <Object>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isEmpty) return;
      var text = buffer.toString();
      buffer.clear();
      if (text == '.') {
        throw const CalculatorException('Некорректное число');
      }
      if (text.startsWith('.')) text = '0$text';
      if (text.endsWith('.')) text = '${text}0';
      final value = double.tryParse(text);
      if (value == null) {
        throw const CalculatorException('Некорректное число');
      }
      tokens.add(value);
    }

    for (final rune in expression.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == ' ') continue;
      if (isNumberChar(ch)) {
        buffer.write(ch);
        continue;
      }
      flush();
      tokens.add(_normalizeOperator(ch));
    }
    flush();
    return tokens;
  }
}

/// Рекурсивный спуск:
///   expression := term (('+' | '−') term)*
///   term       := unary (('×' | '÷') unary)*
///   unary      := ('−' | '+') unary | number
class _Parser {
  _Parser(this._tokens);

  final List<Object> _tokens;
  int _pos = 0;

  Object? get _current => _pos < _tokens.length ? _tokens[_pos] : null;

  double parse() {
    final value = _expression();
    if (_pos != _tokens.length) {
      throw const CalculatorException('Некорректное выражение');
    }
    return value;
  }

  double _expression() {
    var value = _term();
    while (_current == CalculatorLogic.plus ||
        _current == CalculatorLogic.minus) {
      final op = _tokens[_pos++];
      final right = _term();
      value = op == CalculatorLogic.plus ? value + right : value - right;
    }
    return value;
  }

  double _term() {
    var value = _unary();
    while (_current == CalculatorLogic.times ||
        _current == CalculatorLogic.divide) {
      final op = _tokens[_pos++];
      final right = _unary();
      if (op == CalculatorLogic.times) {
        value *= right;
      } else {
        if (right == 0) {
          throw const CalculatorException('Деление на ноль невозможно');
        }
        value /= right;
      }
    }
    return value;
  }

  double _unary() {
    final token = _current;
    if (token == CalculatorLogic.minus) {
      _pos++;
      return -_unary();
    }
    if (token == CalculatorLogic.plus) {
      _pos++;
      return _unary();
    }
    if (token is double) {
      _pos++;
      return token;
    }
    throw const CalculatorException('Некорректное выражение');
  }
}
