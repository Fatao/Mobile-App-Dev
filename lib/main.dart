import 'package:flutter/material.dart';

import 'calculator_logic.dart';
import 'calculator_state.dart';

void main() {
  runApp(const CalculatorApp());
}

/// Корневой виджет. Хранит выбранную тему (дополнительное задание: тёмная тема).
class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: CalculatorPage(
        isDark: _isDark,
        onToggleTheme: () => setState(() => _isDark = !_isDark),
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final CalculatorState _calc = CalculatorState();

  @override
  void dispose() {
    _calc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор'),
        actions: [
          IconButton(
            key: const ValueKey('theme_toggle'),
            tooltip: widget.isDark ? 'Светлая тема' : 'Тёмная тема',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListenableBuilder(
              listenable: _calc,
              builder: (context, _) {
                return Column(
                  children: [
                    Expanded(
                      flex: isLandscape ? 1 : 2,
                      child: _Display(
                        expression: _calc.displayExpression,
                        result: _calc.result,
                        hasError: _calc.hasError,
                      ),
                    ),
                    Expanded(
                      flex: isLandscape ? 3 : 5,
                      child: _Keypad(calc: _calc),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Верхняя область: выражение и результат.
class _Display extends StatelessWidget {
  const _Display({
    required this.expression,
    required this.result,
    required this.hasError,
  });

  final String expression;
  final String result;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final expressionSize = (h * 0.26).clamp(14.0, 32.0).toDouble();
          final resultSize = (h * 0.40).clamp(20.0, 48.0).toDouble();
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  expression,
                  key: const ValueKey('expression'),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: expressionSize,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  result.isEmpty ? ' ' : result,
                  key: const ValueKey('result'),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: resultSize,
                    fontWeight: FontWeight.w600,
                    color: hasError ? scheme.error : scheme.onSurface,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Сетка кнопок. Кнопки растягиваются под доступную высоту и ширину,
/// поэтому элементы не выходят за границы экрана.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.calc});

  final CalculatorState calc;

  @override
  Widget build(BuildContext context) {
    _CalcKey digit(String d) => _CalcKey(
          id: 'key_$d',
          label: d,
          kind: _KeyKind.digit,
          onPressed: () => calc.inputDigit(d),
        );

    _CalcKey op(String id, String symbol) => _CalcKey(
          id: id,
          label: symbol,
          kind: _KeyKind.operator,
          onPressed: () => calc.inputOperator(symbol),
        );

    Widget row(List<Widget> children) => Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Column(
        children: [
          row([
            _CalcKey(
              id: 'key_clear',
              label: 'C',
              kind: _KeyKind.function,
              onPressed: calc.clear,
            ),
            _CalcKey(
              id: 'key_sign',
              label: '+/−',
              kind: _KeyKind.function,
              onPressed: calc.toggleSign,
            ),
            _CalcKey(
              id: 'key_percent',
              label: '%',
              kind: _KeyKind.function,
              onPressed: calc.percent,
            ),
            op('key_div', CalculatorLogic.divide),
          ]),
          row([digit('7'), digit('8'), digit('9'), op('key_mul', CalculatorLogic.times)]),
          row([digit('4'), digit('5'), digit('6'), op('key_sub', CalculatorLogic.minus)]),
          row([digit('1'), digit('2'), digit('3'), op('key_add', CalculatorLogic.plus)]),
          row([
            _CalcKey(
              id: 'key_0',
              label: '0',
              kind: _KeyKind.digit,
              flex: 2,
              onPressed: () => calc.inputDigit('0'),
            ),
            _CalcKey(
              id: 'key_dot',
              label: '.',
              kind: _KeyKind.digit,
              onPressed: calc.inputDot,
            ),
            _CalcKey(
              id: 'key_eq',
              label: '=',
              kind: _KeyKind.equals,
              onPressed: calc.equals,
            ),
          ]),
        ],
      ),
    );
  }
}

enum _KeyKind { digit, function, operator, equals }

class _CalcKey extends StatelessWidget {
  const _CalcKey({
    required this.id,
    required this.label,
    required this.kind,
    required this.onPressed,
    this.flex = 1,
  });

  final String id;
  final String label;
  final _KeyKind kind;
  final VoidCallback onPressed;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background = switch (kind) {
      _KeyKind.digit => scheme.surfaceContainerHighest,
      _KeyKind.function => scheme.secondaryContainer,
      _KeyKind.operator => scheme.tertiaryContainer,
      _KeyKind.equals => scheme.primary,
    };
    final Color foreground = switch (kind) {
      _KeyKind.digit => scheme.onSurface,
      _KeyKind.function => scheme.onSecondaryContainer,
      _KeyKind.operator => scheme.onTertiaryContainer,
      _KeyKind.equals => scheme.onPrimary,
    };

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FilledButton(
          key: ValueKey(id),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: FittedBox(
            child: Text(
              label,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
