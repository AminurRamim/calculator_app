/// Pure Dart calculator logic. It has no Flutter imports, so it can be
/// unit-tested directly. The UI only reads these fields and calls these
/// methods inside setState().
class CalculatorEngine {
  /// Text in the main display: the current entry, a result, or an error.
  String display = '0';

  /// The left operand, stored when an operator is chosen.
  double? firstOperand;

  /// The selected operator: '+', '−', '×', or '÷'.
  String? pendingOperator;

  /// True when the next digit should replace the display instead of
  /// appending to it, for example right after an operator or after '='.
  bool startNewEntry = true;

  /// Set when a calculation fails, such as division by zero or overflow.
  String? error;

  /// A non-fatal hint, such as an incomplete operation. State is kept.
  String? message;

  static const int maxDigits = 15;

  bool get hasError => error != null;

  /// Secondary line above the display, for example "8 ×".
  String get expression => (firstOperand != null && pendingOperator != null)
      ? '${format(firstOperand!)} $pendingOperator'
      : '';

  void inputDigit(String digit) {
    // Recovery path: typing a number after an error starts fresh.
    if (hasError) allClear();
    message = null;

    if (startNewEntry) {
      display = digit;
      startNewEntry = false;
    } else if (display == '0') {
      display = digit; // no leading zeros
    } else if (display.length < maxDigits) {
      display += digit;
    }
  }

  void setOperator(String op) {
    if (hasError) return; // the user must recover first
    message = null;

    // Chaining: "2 + 3 ×" evaluates 2 + 3 first.
    if (pendingOperator != null && !startNewEntry) {
      equals();
      if (hasError) return;
    }
    // When no second number was typed yet, this simply replaces the
    // operator, so the user can change their mind.
    firstOperand = double.parse(display);
    pendingOperator = op;
    startNewEntry = true;
  }

  void equals() {
    if (hasError) return;
    if (pendingOperator == null || firstOperand == null) return;

    // Incomplete input, for example "8 × =". Keep state and give a hint.
    if (startNewEntry) {
      message = 'Enter a second number';
      return;
    }

    final a = firstOperand!;
    final b = double.parse(display);
    double result;

    switch (pendingOperator) {
      case '+':
        result = a + b;
        break;
      case '−':
        result = a - b;
        break;
      case '×':
        result = a * b;
        break;
      case '÷':
        if (b == 0) {
          _setError('Cannot divide by zero');
          return;
        }
        result = a / b;
        break;
      default:
        return;
    }

    if (result.isNaN || result.isInfinite) {
      _setError('Result too large');
      return;
    }

    display = format(result);
    firstOperand = null;
    pendingOperator = null;
    startNewEntry = true;
    message = null;
  }

  /// AC resets the display and all calculator state.
  void allClear() {
    display = '0';
    firstOperand = null;
    pendingOperator = null;
    startNewEntry = true;
    error = null;
    message = null;
  }

  /// C clears only the current entry and keeps the stored operand and
  /// operator. After an error it behaves like AC.
  void clearEntry() {
    if (hasError) {
      allClear();
      return;
    }
    display = '0';
    message = null;
  }

  void _setError(String text) {
    error = text;
    display = text;
    message = 'Tap a number or AC to start over';
    firstOperand = null;
    pendingOperator = null;
    startNewEntry = true;
  }

  /// Formats a double for display: 56.0 becomes "56", and 1/3 becomes
  /// "0.3333333333".
  static String format(double value) {
    if (value == 0) return '0'; // also avoids "-0"
    if (value == value.truncateToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    var text = value.toStringAsPrecision(10);
    if (text.contains('.') && !text.contains('e')) {
      text = text
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }
}
