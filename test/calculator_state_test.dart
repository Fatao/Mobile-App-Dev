import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/calculator_logic.dart';
import 'package:my_app/calculator_state.dart';

/// Нажимает «кнопки» по строке. Обозначения:
/// цифры, '.', '+', '-', '*', '/', '=', 'C', 's' (+/−), '%'.
CalculatorState tap(String keys) {
  final calc = CalculatorState();
  for (final k in keys.split('')) {
    switch (k) {
      case '.':
        calc.inputDot();
        break;
      case '+':
        calc.inputOperator(CalculatorLogic.plus);
        break;
      case '-':
        calc.inputOperator(CalculatorLogic.minus);
        break;
      case '*':
        calc.inputOperator(CalculatorLogic.times);
        break;
      case '/':
        calc.inputOperator(CalculatorLogic.divide);
        break;
      case '=':
        calc.equals();
        break;
      case 'C':
        calc.clear();
        break;
      case 's':
        calc.toggleSign();
        break;
      case '%':
        calc.percent();
        break;
      default:
        calc.inputDigit(k);
    }
  }
  return calc;
}

void main() {
  const minus = CalculatorLogic.minus;

  group('Тестовые сценарии из методички', () {
    test('12 + 8 = 20', () => expect(tap('12+8=').result, '20'));
    test('15 − 7 = 8', () => expect(tap('15-7=').result, '8'));
    test('6 × 7 = 42', () => expect(tap('6*7=').result, '42'));
    test('20 ÷ 4 = 5', () => expect(tap('20/4=').result, '5'));
    test('12.5 + 0.5 = 13', () => expect(tap('12.5+0.5=').result, '13'));

    test('5 ÷ 0 даёт сообщение об ошибке', () {
      final calc = tap('5/0=');
      expect(calc.hasError, isTrue);
      expect(calc.result, 'Деление на ноль невозможно');
    });
  });

  group('Логика', () {
    test('приоритет операций', () => expect(tap('2+3*4=').result, '14'));
    test('погрешность double скрыта', () => expect(tap('0.1+0.2=').result, '0.3'));
    test('предварительный результат', () => expect(tap('2+3').result, '5'));
    test('оператор заменяется', () => expect(tap('5+*3=').result, '15'));
    test('продолжение с результатом', () => expect(tap('2+3=*4=').result, '20'));
    test('после ошибки ввод начинается заново', () {
      final calc = tap('5/0=7');
      expect(calc.hasError, isFalse);
      expect(calc.expression, '7');
    });
    test('кнопка очистки', () {
      final calc = tap('12+8C');
      expect(calc.expression, '');
      expect(calc.result, '');
    });
    test('ведущие нули', () => expect(tap('005').expression, '5'));
    test('десятичная точка', () {
      expect(tap('.5').expression, '0.5');
      expect(tap('1..2').expression, '1.2');
    });
  });

  group('Дополнительное задание: +/− и %', () {
    test('смена знака числа', () {
      expect(tap('5s').expression, '${minus}5');
      expect(tap('5ss').expression, '5');
    });
    test('смена знака после + превращает его в −', () {
      expect(tap('5+3s').expression, '5${minus}3');
    });
    test('смена знака после ×', () {
      final calc = tap('5*3s=');
      expect(calc.result, '${minus}15');
    });
    test('процент', () => expect(tap('50%').expression, '0.5'));
  });
}
