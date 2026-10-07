import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_app/calculator_engine.dart';
import 'package:calculator_app/main.dart';

/// Feeds a sequence of key labels into the engine, for example ['8', '×', '7', '='].
CalculatorEngine run(List<String> keys) {
  final e = CalculatorEngine();
  for (final k in keys) {
    switch (k) {
      case '+':
      case '−':
      case '×':
      case '÷':
        e.setOperator(k);
        break;
      case '=':
        e.equals();
        break;
      case 'AC':
        e.allClear();
        break;
      case 'C':
        e.clearEntry();
        break;
      default:
        e.inputDigit(k);
    }
  }
  return e;
}

void main() {
  group('Core arithmetic', () {
    test('multiply', () => expect(run(['8', '×', '7', '=']).display, '56'));
    test('add', () => expect(run(['1', '2', '+', '3', '0', '=']).display, '42'));
    test('subtract to negative',
        () => expect(run(['9', '−', '1', '2', '=']).display, '-3'));
    test('divide with decimal result',
        () => expect(run(['7', '÷', '2', '=']).display, '3.5'));
    test('repeating decimal is rounded',
        () => expect(run(['1', '÷', '3', '=']).display, '0.3333333333'));
    test('no leading zeros', () => expect(run(['0', '0', '7']).display, '7'));
    test('changing the operator uses the latest one',
        () => expect(run(['8', '+', '×', '3', '=']).display, '24'));
    test('chained operations evaluate left to right',
        () => expect(run(['2', '+', '3', '×', '4', '=']).display, '20'));
    test('new digit after a result starts a new number',
        () => expect(run(['2', '+', '2', '=', '5']).display, '5'));
  });

  group('Feature: Clear / all clear', () {
    test('AC resets everything', () {
      final e = run(['8', '×', '5', 'AC']);
      expect(e.display, '0');
      expect(e.firstOperand, isNull);
      expect(e.pendingOperator, isNull);
    });
    test('C clears only the current entry', () {
      expect(run(['8', '×', '5', 'C', '3', '=']).display, '24');
    });
  });

  group('Feature: Error handling', () {
    test('division by zero shows a recoverable error', () {
      final e = run(['5', '÷', '0', '=']);
      expect(e.hasError, isTrue);
      expect(e.display, 'Cannot divide by zero');
      e.inputDigit('4'); // recovery
      expect(e.hasError, isFalse);
      expect(e.display, '4');
    });
    test('operators are ignored while in the error state', () {
      final e = run(['5', '÷', '0', '=', '+']);
      expect(e.hasError, isTrue);
    });
    test('incomplete input keeps state and shows a hint', () {
      final e = run(['8', '×', '=']);
      expect(e.message, 'Enter a second number');
      expect(e.hasError, isFalse);
      e.inputDigit('2');
      e.equals();
      expect(e.display, '16');
    });
    test('equals with no operator does nothing',
        () => expect(run(['9', '=']).display, '9'));
  });

  group('Widget tests', () {
    testWidgets('tapping 8 × 7 = shows 56', (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      for (final k in ['8', '×', '7', '=']) {
        await tester.tap(find.byKey(ValueKey('btn_$k')));
        await tester.pump();
      }
      expect(
        tester.widget<Text>(find.byKey(const Key('display'))).data,
        '56',
      );
    });

    testWidgets('Feature: Theme toggle switches to dark', (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      BuildContext ctx() => tester.element(find.byType(CalculatorScreen));
      expect(Theme.of(ctx()).brightness, Brightness.light);

      await tester.tap(find.byKey(const Key('theme_toggle')));
      await tester.pumpAndSettle();
      expect(Theme.of(ctx()).brightness, Brightness.dark);
    });

    testWidgets('divide by zero shows an error message in the UI',
        (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      for (final k in ['5', '÷', '0', '=']) {
        await tester.tap(find.byKey(ValueKey('btn_$k')));
        await tester.pump();
      }
      expect(find.text('Cannot divide by zero'), findsOneWidget);
      expect(find.byKey(const Key('message')), findsOneWidget);
    });
  });
}
