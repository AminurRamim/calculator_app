import 'package:flutter/material.dart';

import 'calculator_engine.dart';

void main() => runApp(const CalculatorApp());

/// Root widget. It owns the theme state, so switching themes rebuilds
/// MaterialApp, and MaterialApp animates between the two themes.
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
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      // Smooth transition: every surface lerps between the two themes.
      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeInOut,
      home: CalculatorScreen(
        isDark: _isDark,
        onThemeToggle: () => setState(() => _isDark = !_isDark),
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
  });

  final bool isDark;
  final VoidCallback onThemeToggle;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorEngine _engine = CalculatorEngine();

  /// Every button routes through this, so the UI is always rebuilt from
  /// the engine's state and never from scattered side effects.
  void _run(VoidCallback action) => setState(action);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          IconButton(
            key: const Key('theme_toggle'),
            tooltip:
                widget.isDark ? 'Switch to light theme' : 'Switch to dark theme',
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(flex: 2, child: _buildDisplay(context)),
              const SizedBox(height: 12),
              Expanded(flex: 5, child: _buildKeypad()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplay(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _engine.expression,
            key: const Key('expression'),
            style: text.titleLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (_engine.message != null)
            Text(
              _engine.message!,
              key: const Key('message'),
              style: text.bodyMedium?.copyWith(color: cs.error),
            ),
          // liveRegion makes TalkBack announce new results and errors.
          Semantics(
            liveRegion: true,
            label: _engine.hasError ? 'Error' : 'Display',
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _engine.display,
                key: const Key('display'),
                maxLines: 1,
                style: text.displayLarge?.copyWith(
                  color: _engine.hasError ? cs.error : cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    Widget digit(String d) => CalcButton(
          label: d,
          kind: ButtonKind.digit,
          onTap: () => _run(() => _engine.inputDigit(d)),
        );

    Widget op(String symbol, String spoken) => CalcButton(
          label: symbol,
          semanticLabel: spoken,
          kind: ButtonKind.operator,
          onTap: () => _run(() => _engine.setOperator(symbol)),
        );

    Widget row(List<Widget> children) => Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );

    return Column(
      children: [
        row([
          CalcButton(
            label: 'AC',
            semanticLabel: 'All clear',
            kind: ButtonKind.function,
            flex: 2,
            onTap: () => _run(_engine.allClear),
          ),
          CalcButton(
            label: 'C',
            semanticLabel: 'Clear entry',
            kind: ButtonKind.function,
            onTap: () => _run(_engine.clearEntry),
          ),
          op('÷', 'divide'),
        ]),
        row([digit('7'), digit('8'), digit('9'), op('×', 'multiply')]),
        row([digit('4'), digit('5'), digit('6'), op('−', 'minus')]),
        row([digit('1'), digit('2'), digit('3'), op('+', 'plus')]),
        row([
          CalcButton(
            label: '0',
            kind: ButtonKind.digit,
            flex: 3,
            onTap: () => _run(() => _engine.inputDigit('0')),
          ),
          CalcButton(
            label: '=',
            semanticLabel: 'equals',
            kind: ButtonKind.equals,
            onTap: () => _run(_engine.equals),
          ),
        ]),
      ],
    );
  }
}

enum ButtonKind { digit, operator, function, equals }

/// One reusable button widget for the entire keypad.
class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.kind,
    required this.onTap,
    this.semanticLabel,
    this.flex = 1,
  });

  final String label;
  final String? semanticLabel;
  final ButtonKind kind;
  final VoidCallback onTap;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (kind) {
      ButtonKind.digit => (cs.surfaceContainerHigh, cs.onSurface),
      ButtonKind.operator => (cs.primary, cs.onPrimary),
      ButtonKind.function => (cs.tertiaryContainer, cs.onTertiaryContainer),
      ButtonKind.equals => (cs.secondary, cs.onSecondary),
    };

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Semantics(
          button: true,
          label: semanticLabel ?? label,
          onTap: onTap,
          excludeSemantics: true,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              key: ValueKey('btn_$label'),
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
