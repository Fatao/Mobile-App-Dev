import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';

void main() {
  Future<void> setScreen(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> press(WidgetTester tester, List<String> ids) async {
    for (final id in ids) {
      await tester.tap(find.byKey(ValueKey(id)));
      await tester.pump();
    }
  }

  String resultText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('result'))).data!;

  testWidgets('12 + 8 = 20', (tester) async {
    await setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(const CalculatorApp());

    await press(tester, ['key_1', 'key_2', 'key_add', 'key_8', 'key_eq']);

    expect(resultText(tester), '20');
  });

  testWidgets('5 ÷ 0 показывает ошибку', (tester) async {
    await setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(const CalculatorApp());

    await press(tester, ['key_5', 'key_div', 'key_0', 'key_eq']);

    expect(resultText(tester), 'Деление на ноль невозможно');
  });

  testWidgets('тёмная тема переключается', (tester) async {
    await setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(const CalculatorApp());

    Brightness brightness() =>
        Theme.of(tester.element(find.byType(Scaffold))).brightness;

    expect(brightness(), Brightness.light);
    await tester.tap(find.byKey(const ValueKey('theme_toggle')));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
  });

  testWidgets('нет переполнения на маленьком экране', (tester) async {
    await setScreen(tester, const Size(320, 480));
    await tester.pumpWidget(const CalculatorApp());
    await press(tester, ['key_9', 'key_9', 'key_mul', 'key_9', 'key_9']);
    expect(tester.takeException(), isNull);
  });
}
