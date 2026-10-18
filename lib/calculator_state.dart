import 'package:flutter/foundation.dart';

import 'calculator_logic.dart';

// Состояние калькулятора: хранит вводимое выражение и результат,
// обрабатывает нажатия кнопок. Вычисления делегирует CalculatorLogic.
class CalculatorState extends ChangeNotifier {
  static const int maxLength = 40;

  String _expression = '';
  String _result = '';
  bool _justEvaluated = false;
  bool _hasError = false;

  // Выражение в том виде, как его вводит пользователь («12+8»).
  String get expression => _expression;

  // Результат, предварительный результат или сообщение об ошибке.
  String get result => _result;

  bool get hasError => _hasError;

  String get displayExpression => _expression.isEmpty ? '0' : _expression;

  //  Ввод

  void inputDigit(String digit) {
    _resetIfFinished();
    if (_expression.length >= maxLength) return;
    final start = _lastNumberStart();
    final current = _expression.substring(start);
    if (current == '0') {
      _expression = _expression.substring(0, start) + digit;
    } else {
      _expression += digit;
    }
    _refresh();
  }

  void inputDot() {
    _resetIfFinished();
    if (_expression.length >= maxLength) return;
    final start = _lastNumberStart();
    final current = _expression.substring(start);
    if (current.contains('.')) return;
    _expression += current.isEmpty ? '0.' : '.';
    _refresh();
  }

  void inputOperator(String op) {
    if (_hasError) return;
    if (_justEvaluated) {
      // Продолжаем вычисления с предыдущим результатом.
      _expression = _result;
      _result = '';
      _justEvaluated = false;
    }
    if (_expression.isEmpty) {
      _expression = op == CalculatorLogic.minus ? op : '0$op';
    } else if (_expression == CalculatorLogic.minus) {
      return;
    } else if (CalculatorLogic.isOperator(
      _expression[_expression.length - 1],
    )) {
      // Два оператора подряд: заменяем предыдущий.
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else {
      if (_expression.length >= maxLength) return;
      _expression += op;
    }
    _refresh();
  }

  void clear() {
    _expression = '';
    _result = '';
    _justEvaluated = false;
    _hasError = false;
    notifyListeners();
  }

  void equals() {
    if (_hasError || _justEvaluated) return;
    final trimmed = _closeOpenParentheses(_trimTrailingOperator(_expression));
    if (trimmed.isEmpty) return;
    try {
      final value = CalculatorLogic.evaluate(trimmed);
      _expression = trimmed;
      _result = CalculatorLogic.format(value);
      _justEvaluated = true;
    } on CalculatorException catch (e) {
      _expression = trimmed;
      _result = e.message;
      _hasError = true;
    }
    notifyListeners();
  }

  //  Дополнительное задание: «+/−» и «%»

  // Меняет знак последнего введённого числа.
  void toggleSign() {
    if (_hasError) return;
    if (_justEvaluated) {
      final base = _result;
      _expression = base.startsWith(CalculatorLogic.minus)
          ? base.substring(1)
          : '${CalculatorLogic.minus}$base';
      _justEvaluated = false;
      _refresh();
      return;
    }
    final start = _lastNumberStart();
    if (start == _expression.length) return; // в конце нет числа

    if (start == 0) {
      _expression = '${CalculatorLogic.minus}$_expression';
    } else {
      final prev = _expression[start - 1];
      final head = _expression.substring(0, start - 1);
      final tail = _expression.substring(start);
      if (prev == CalculatorLogic.minus) {
        final isUnary =
            start - 1 == 0 ||
            CalculatorLogic.isOperator(_expression[start - 2]);
        _expression = isUnary
            ? '$head$tail'
            : '$head${CalculatorLogic.plus}$tail';
      } else if (prev == CalculatorLogic.plus) {
        _expression = '$head${CalculatorLogic.minus}$tail';
      } else {
        // После × или ÷ ставим унарный минус: «5×−3».
        _expression =
            '${_expression.substring(0, start)}${CalculatorLogic.minus}$tail';
      }
    }
    _refresh();
  }

  // Делит последнее введённое число на 100.
  void percent() {
    if (_hasError) return;
    if (_justEvaluated) {
      final value = CalculatorLogic.evaluate(_result) / 100;
      _expression = CalculatorLogic.format(value);
      _justEvaluated = false;
      _refresh();
      return;
    }
    final start = _lastNumberStart();
    if (start == _expression.length) return;
    final value = CalculatorLogic.evaluate(_expression.substring(start)) / 100;
    _expression =
        _expression.substring(0, start) + CalculatorLogic.format(value);
    _refresh();
  }

  // Заменяет последнее введённое число на его синус (угол в градусах).
  void sin() {
    if (_hasError) return;
    if (_justEvaluated) {
      final value = CalculatorLogic.sinDegrees(
        CalculatorLogic.evaluate(_result),
      );
      _expression = CalculatorLogic.format(value);
      _justEvaluated = false;
      _refresh();
      return;
    }
    if (_expression.isEmpty ||
        CalculatorLogic.isOperator(_expression[_expression.length - 1])) {
      if (_expression.length + 4 > maxLength) return;
      _expression += 'sin(';
      _refresh();
      return;
    }
    final start = _lastNumberStart();
    if (start == _expression.length) return;
    final angle = CalculatorLogic.evaluate(_expression.substring(start));
    _expression =
        _expression.substring(0, start) +
        CalculatorLogic.format(CalculatorLogic.sinDegrees(angle));
    _refresh();
  }

  //  Вспомогательные методы

  // Начало последнего числа в выражении (или длина строки, если в конце оператор).
  int _lastNumberStart() {
    var i = _expression.length;
    while (i > 0 && CalculatorLogic.isNumberChar(_expression[i - 1])) {
      i--;
    }
    return i;
  }

  void _resetIfFinished() {
    if (_hasError || _justEvaluated) {
      _expression = '';
      _result = '';
      _hasError = false;
      _justEvaluated = false;
    }
  }

  String _trimTrailingOperator(String text) {
    if (text.isNotEmpty && CalculatorLogic.isOperator(text[text.length - 1])) {
      return text.substring(0, text.length - 1);
    }
    return text;
  }

  String _closeOpenParentheses(String text) {
    var open = 0;
    for (final character in text.split('')) {
      if (character == '(') open++;
      if (character == ')') open--;
    }
    return open > 0 ? '$text${List.filled(open, ')').join()}' : text;
  }

  void _refresh() {
    _result = _preview();
    notifyListeners();
  }

  // Предварительный результат, пока пользователь вводит выражение.
  // Ошибки во время набора не показываем.
  String _preview() {
    final trimmed = _trimTrailingOperator(_expression);
    var hasOperator = false;
    for (var i = 1; i < trimmed.length; i++) {
      if (CalculatorLogic.isOperator(trimmed[i])) {
        hasOperator = true;
        break;
      }
    }
    if (!hasOperator) return '';
    try {
      return CalculatorLogic.format(CalculatorLogic.evaluate(trimmed));
    } on CalculatorException {
      return '';
    }
  }
}
